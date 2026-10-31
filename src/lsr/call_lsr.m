function [x, fval, exitflag, com] = call_lsr(com, options)
%call_lsr - 局所探索の試行とフェーズを実行し最良解を選ぶ
%
%   [x, fval, exitflag, com] = call_lsr(com, options) は、上限断面の
%   制約違反を確認して局所探索を実行し、試行履歴から最良解を返す。
%
%   入力引数:
%     com     - モデルと断面リストの共通データ
%     options - 探索条件と履歴保存・再開条件
%
%   出力引数:
%     x        - 選択した設計変数 [nvar×1]
%     fval     - 選択した解の目的関数値
%     exitflag - 探索の終了状態
%     com      - 制約分類と制約数を設定した共通データ

% --- common ---
secmgr = com.secmgr;
max_idphase = min(options.maxphase, com.sectionList.getMaxIdPhase() + 1);

% 診断ロガーを今回実行の設定へ初期化する（診断ファイル未指定なら無効）
init_logger(options.lsfr_diagnostic_file);

% 上下限値
lb = secmgr.lb;
ub = secmgr.ub;

% 初期断面での部材長を算出
secdim0 = secmgr.findNearestSection(ub, options);
com = update_frame_data(secdim0, com, options);
lm = calc_member_length_from_node(com.node, ...
  [com.member.property.idnode1 com.member.property.idnode2]);

% 履歴準備
trials = [];
trials_history = [];
xopt = [];

% 履歴読み込み
if ~isempty(options.matfile)
  resume = load(options.matfile);
  validate_resume_variables();
  resume.history = ensure_lsr_history_info(resume.history);
end

% 初期ペナルティ係数
options.idphase = max_idphase;
% ub/lb の断面を idphase 設定後に1回ずつ写像し、ペナルティ係数と
% 制約チェックで共有する（_xvar ラッパ内の再写像を避ける）
secdim_ub = secmgr.findNearestSection(ub, options);
secdim_lb = secmgr.findNearestSection(lb, options);
com = update_frame_data(secdim_lb, com, options);
flb = objective_lsr(secdim_lb, secmgr, com.node, com.section, ...
  com.member, com.floor);
com = update_frame_data(secdim_ub, com, options);
fub = objective_lsr(secdim_ub, secmgr, com.node, com.section, ...
  com.member, com.floor);
f0 = (fub+flb)/2;

% 上限断面の警告に使う部材・材料・検定位置を完全結果から取得する。
[cvec, result] = analysis_constraint(ub, secdim_ub, com, options);
check_max_section_violation(cvec, result, com, options);

% LSR全体で不変の制約数と制約ラベルを共通構造体へ保存する
com.ncon = result.ncon;
com.conlabel = result.conlabel;

% 初期解
if ~isempty(options.x0)
  x0 = options.x0;
end

% --- Local Search ---
iter_set = options.iter_set;
if isfinite(options.idtrial_resume)
  iter_set = iter_set(iter_set>=options.idtrial_resume);
end
if isempty(iter_set)
  error('call_lsr:EmptyIterSet', ...
    'No trial remains after applying idtrial_resume.');
end
for idtrial = iter_set
  rng(idtrial);

  % 履歴ファイル読み込み
  if (options.idtrial_resume == idtrial && exist('resume','var'))
    [x0, history] = load_trial;
    start_idphase = options.idphase_resume;
  else
    % ランダム初期解生成
    if idtrial>1 || isempty(options.x0)
      x0 = secmgr.generateRandomXvar(idtrial, lm, options);
    end
    history = [];
    start_idphase = 1;
  end
  for idphase = start_idphase:max_idphase
    options.idtrial = idtrial;
    options.idphase = idphase;
    options.mu = f0*options.mu0(options.idphase);
    if (idphase~=options.idphase_resume)
      if (idphase>1)
        x0 = xopt;
      end
      history = [];
    end
    [xopt, fval, exitflag, history] = lsr(x0, com, history, options);
    save_trial
  end
end

% 最良解の選択
best = select_best_lsr_history(trials.history, options.iter_set, ...
  max_idphase);
x = best.xvar(:);
fval = best.fval;

% 許容解が見つからなかった場合
if best.maxvio > PRM.TOL_MAX_VIOLATION
  exitflag = PRM.EXITFLAG_NO_FEASIBLE;
end

return
%--------------------------------------------------------------------------
  function save_trial
  %save_trial - 現在の試行・フェーズの結果を履歴ファイルへ保存する
  %
  %   save_trial は、外側の探索結果をtrialsとtrials_historyへ反映する。
  %   履歴ファイルの指定がない場合は保存しない。
  %
  %   入力引数:
  %     なし（外側の探索状態を参照）
  %
  %   出力引数:
  %     なし（外側のtrialsとtrials_historyを更新）

    if isempty(options.historyfile)
      return
    end
    if isempty(trials)
      trial_filename = options.historyfile;
      trials = matfile(trial_filename, 'Writable', true);
    end
    n1 = max(options.iter_set);
    n2 = max_idphase;
    nx = size(xopt, 2);
    if isempty(trials_history)
      initialize_trials_history(n1, n2)
    end
    if needs_trial_initialization(nx, n1, n2)
      initialize_trials(nx, n1, n2)
    end
    n_ = length(history.iter);
    if n2==1
      trials.x0(:, idtrial) = x0(:);
      trials.xopt(:, idtrial) = xopt(:);
    else
      trials.x0(:, idtrial, idphase) = x0(:);
      trials.xopt(:, idtrial, idphase) = xopt(:);
    end
    trials.fval(idtrial, idphase) = fval;
    trials.iter(idtrial, idphase) = history.iter(n_);
    trials.time(idtrial, idphase) = history.time(n_);
    trials.maxvio(idtrial, idphase) = history.maxvio;
    trials.nexec(idtrial, idphase) = history.nexec(n_);
    trials_history(idtrial, idphase) = history;
    trials.history = trials_history;

    return
  end
%--------------------------------------------------------------------------
  function initialize_trials(nx, n1, n2)
  %initialize_trials - 試行履歴の数値配列を確保する
  %
  %   initialize_trials(nx, n1, n2) は、試行数とフェーズ数に合わせて
  %   配列を確保し、再開時は既存の記録をコピーする。
  %
  %   入力引数:
  %     nx - 設計変数の数
  %     n1 - 試行数
  %     n2 - フェーズ数
  %
  %   出力引数:
  %     なし（外側のtrialsを更新）

    x0_array = nan(nx, n1, n2);
    xopt_array = nan(nx, n1, n2);
    fval_array = nan(n1, n2);
    iter_array = nan(n1, n2);
    time_array = nan(n1, n2);
    maxvio_array = nan(n1, n2);
    nexec_array = nan(n1, n2);
    if exist('resume', 'var')
      x0_array = copy_array(x0_array, resume.x0);
      xopt_array = copy_array(xopt_array, resume.xopt);
      fval_array = copy_array(fval_array, resume.fval);
      iter_array = copy_array(iter_array, resume.iter);
      time_array = copy_array(time_array, resume.time);
      maxvio_array = copy_array(maxvio_array, resume.maxvio);
      nexec_array = copy_array(nexec_array, resume.nexec);
    end
    if n2 == 1
      trials.x0 = x0_array(:,:,1);
      trials.xopt = xopt_array(:,:,1);
    else
      trials.x0 = x0_array;
      trials.xopt = xopt_array;
    end
    trials.fval = fval_array;
    trials.iter = iter_array;
    trials.time = time_array;
    trials.maxvio = maxvio_array;
    trials.nexec = nexec_array;

    return
  end
%--------------------------------------------------------------------------
  function initialize_trials_history(n1, n2)
  %initialize_trials_history - 試行ごとの探索履歴配列を確保する
  %
  %   initialize_trials_history(n1, n2) は、指定サイズの履歴配列を
  %   確保し、再開時は保存済みの履歴を引き継ぐ。
  %
  %   入力引数:
  %     n1 - 試行数
  %     n2 - フェーズ数
  %
  %   出力引数:
  %     なし（外側のtrials_historyを更新）

    if exist('resume', 'var')
      trials_history = resume.history;
      if size(trials_history, 1) < n1 || size(trials_history, 2) < n2
        trials_history(n1, n2) = struct(history);
      end
      trials_history = trials_history(1:n1, 1:n2);
    else
      trials_history = struct(history);
      trials_history(n1, n2) = struct(history);
    end

    return
  end
%--------------------------------------------------------------------------
  function validate_resume_variables
  %validate_resume_variables - 再開用データに必須変数があるか確認する
  %
  %   validate_resume_variables は、保存履歴の変数名を確認し、
  %   必須変数が不足する場合はエラーにする。
  %
  %   入力引数:
  %     なし（外側のresumeを参照）
  %
  %   出力引数:
  %     なし

    names = {'x0','xopt','fval','iter','time','maxvio','nexec','history'};
    for i = 1:numel(names)
      if ~isfield(resume, names{i})
        error('call_lsr:InvalidResumeFile', ...
          'Resume file does not contain %s.', names{i});
      end
    end

    return
  end
%--------------------------------------------------------------------------
  function array = copy_array(array, source)
  %copy_array - 旧履歴配列の共通範囲を新しい配列へコピーする
  %
  %   array = copy_array(array, source) は、各次元の共通範囲だけを
  %   コピーし、新たに確保した範囲の初期値を保つ。
  %
  %   入力引数:
  %     array  - コピー先の配列
  %     source - 保存済みの配列
  %
  %   出力引数:
  %     array - 共通範囲を反映した配列

    array_size = size(array);
    source_size = size(source);
    nd = max(numel(array_size), numel(source_size));
    array_size(end+1:nd) = 1;
    source_size(end+1:nd) = 1;
    subs = cell(1, nd);
    for i = 1:nd
      subs{i} = 1:min(array_size(i), source_size(i));
    end
    array(subs{:}) = source(subs{:});

    return
  end
%--------------------------------------------------------------------------
  function tf = needs_trial_initialization(nx, n1, n2)
  %needs_trial_initialization - 履歴の変数とサイズを確認する
  %
  %   tf = needs_trial_initialization(nx, n1, n2) は、履歴配列の
  %   変数不足またはサイズの不一致があればtrueを返す。
  %
  %   入力引数:
  %     nx - 設計変数の数
  %     n1 - 試行数
  %     n2 - フェーズ数
  %
  %   出力引数:
  %     tf - 配列の初期化が必要か

    vars = who(trials);
    if isempty(vars)
      tf = true;
      return
    end
    vector_size = [nx n1];
    if n2>1
      vector_size = [nx n1 n2];
    end
    tf = ~has_trial_size(vars, 'x0', vector_size) ...
      || ~has_trial_size(vars, 'xopt', vector_size) ...
      || ~has_trial_size(vars, 'fval', [n1 n2]) ...
      || ~has_trial_size(vars, 'iter', [n1 n2]) ...
      || ~has_trial_size(vars, 'time', [n1 n2]) ...
      || ~has_trial_size(vars, 'maxvio', [n1 n2]) ...
      || ~has_trial_size(vars, 'nexec', [n1 n2]) ...
      || ~has_trial_size(vars, 'history', [n1 n2]);

    return
  end
%--------------------------------------------------------------------------
  function tf = has_trial_size(vars, name, expected_size)
  %has_trial_size - 保存変数の存在と配列サイズを照合する
  %
  %   tf = has_trial_size(vars, name, expected_size) は、履歴に変数が
  %   存在し、要求サイズと一致する場合にtrueを返す。
  %
  %   入力引数:
  %     vars          - 履歴に保存された変数名
  %     name          - 確認する変数名
  %     expected_size - 要求する配列サイズ
  %
  %   出力引数:
  %     tf - 変数の存在とサイズが一致するか

    if ~ismember(name, vars)
      tf = false;
      return
    end
    tf = isequal(size(trials, name), expected_size);

    return
  end
%--------------------------------------------------------------------------
  function [x0, history] = load_trial
  %load_trial - 指定した試行と反復回数の履歴を読み出す
  %
  %   [x0, history] = load_trial は、再開条件に対応する保存履歴を
  %   選び、再開位置の設計変数を返す。
  %
  %   入力引数:
  %     なし（外側のresumeとoptionsを参照）
  %
  %   出力引数:
  %     x0      - 再開位置の設計変数
  %     history - 再開する試行・フェーズの履歴

    idtrial_ = options.idtrial_resume;
    idphase_ = options.idphase_resume;
    iter_ = options.iter_resume;
    missing_trial = size(resume.history, 1) < idtrial_;
    missing_phase = size(resume.history, 2) < idphase_;
    if missing_trial || missing_phase
      msg = 'Resume history(%d,%d) does not exist.';
      error('call_lsr:ResumeHistoryNotFound', msg, idtrial_, idphase_);
    end
    history = resume.history(idtrial_, idphase_);
    iter_index = find(history.iter == iter_);
    if numel(iter_index) ~= 1
      error('call_lsr:ResumeIterNotFound', ...
        'Resume iter %d does not exist.', iter_);
    end
    x0 = history.xvar(iter_index, :);

    return
  end
end
