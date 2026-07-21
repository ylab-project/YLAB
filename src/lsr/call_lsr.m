function [x, fval, exitflag, com] = call_lsr(com, options)
% --- common ---
secmgr = com.secmgr;
section = com.section;
member = com.member;
baseline = com.baseline;
node = com.node;
story = com.story;
floor = com.floor;
max_idphase = min(options.maxphase, com.sectionList.getMaxIdPhase() + 1);

% 診断ロガーを今回実行の設定へ初期化する（診断ファイル未指定なら無効）
init_logger(options.lsfr_diagnostic_file);

% 上下限値
lb = secmgr.lb;
ub = secmgr.ub;

% 初期断面での部材長を算出
secdim0 = secmgr.findNearestSection(ub, options);
[~, ~, lm] = update_geometry_z(secdim0, baseline, node, ...
  story, floor, section, member, options);

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
fub = objective_lsr(ub, secmgr, baseline, node, section, ...
  member, story, floor, options);
flb = objective_lsr(lb, secmgr, baseline, node, section, ...
  member, story, floor, options);
f0 = (fub+flb)/2;

% 最大断面での制約チェック
[cvec_ub, result_ub] = analysis_constraint(ub, com, options);
check_max_section_violation(cvec_ub, result_ub, options);

% LSR全体で不変の制約数を共通構造体へ保存する
com.ncon = result_ub.ncon;

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
  end
%--------------------------------------------------------------------------
  function initialize_trials(nx, n1, n2)
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
  end
%--------------------------------------------------------------------------
  function tf = has_trial_size(vars, name, expected_size)
    if ~ismember(name, vars)
      tf = false;
      return
    end
    tf = isequal(size(trials, name), expected_size);
  end
%--------------------------------------------------------------------------
  function [x0, history] = load_trial
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

%--------------------------------------------------------------------------
function check_max_section_violation(cvec, result, options) %#ok<INUSD>
%check_max_section_violation - 最大断面での制約違反チェック
%
%   check_max_section_violation(cvec, result, options) は、
%   断面サイズ依存の制約（ncon[1]-[11]）のみを対象に
%   カテゴリ別の違反件数を集計しワーニングを出す。
%
%   入力引数:
%     cvec    - 制約値ベクトル [1×ncon]
%     result  - 結果構造体（ncon, conlabel）
%     options - オプション構造体（未使用）
  ncon = result.ncon;
  label = result.conlabel;
  % 断面サイズ依存の制約（[1]-[11]）
  ncat = 11;
  parts = {};
  idx = 0;
  for k = 1:ncat
    vio = cvec(idx+1:idx+ncon(k));
    nvio = sum(vio > 0);
    if nvio > 0
      parts{end+1} = sprintf('%s:%d件', label{k}, nvio); %#ok<AGROW>
    end
    idx = idx + ncon(k);
  end
  if ~isempty(parts)
    detail = strjoin(parts, ', ');
    throw_warn('List', 'MaxSectionViolation', detail);
  end

  return
end
