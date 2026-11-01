function [xopt, fopt, exitflag, history] = lsr(xvar, com, history, options)
%lsr - 近傍探索と復元候補の実評価で設計変数を更新する
%
%   [xopt, fopt, exitflag, history] = lsr(xvar, com, history, options)
%   は、LSRまたはLSFRの候補を同じペナルティ係数で比較する。
%   幅厚比・群種別の復元候補は写像済み断面と対で実評価へ渡す。
%
%   入力引数:
%     xvar    - 初期設計変数
%     com     - 断面・部材・解析条件の共通データ
%     history - 再開する探索履歴（新規探索時は空）
%     options - 探索条件と実行オプション
%
%   出力引数:
%     xopt, fopt - 選択した設計変数と目的関数値
%     exitflag   - 探索の終了状態
%     history    - 各反復の評価値と選択した設計変数

do_lsfr = strcmp(options.algorithm, 'LSFR') || ...
  (strcmp(options.algorithm, 'LSR_LSFR') && options.idphase >= 2);
is_pure_lsr = ~do_lsfr;
collect_lsr_timing = is_pure_lsr && ~isempty(options.lsfr_diagnostic_file);

tic;
% 共通定数
max_iter = options.maxiter_in_LS;
if ~isfinite(max_iter)
  max_iter = 200;
end
ppp = 3;

% 共通配列
matF = com.material.F;
matGrade = com.material.steel_grade;
secmgr = com.secmgr;
% member_girder = com.member.girder;
% member_property = com.member.girder;
isvar = com.design.variable.isvar;

% 条件設定
mu = options.mu;
r = options.r;
display_mode = options.display;
% max_iter = options.maxiter_in_LS;
do_restration = options.do_restration;
% do_parallel = options.do_parallel;
copts = options.coptions;
consider_girder_height_gap = copts.consider_girder_height_gap_var | ...
  copts.consider_girder_height_gap_section;
consider_girder_height_smooth = copts.consider_girder_height_smooth_var;
consider_column_diameter_gap = copts.consider_column_diameter_gap;
consider_slenderness_ratio = copts.consider_slenderness_ratio;
consider_joint_bearing_strength = copts.consider_joint_bearing_strength;
secmgr.idphase = options.idphase;
com = prepare_lsr_worker_com(com, options.do_parallel);

resume_rng_state = [];
if ~isempty(history)
  resume_rng_state = rng;
end

% LSFRは初期値・前フェーズの採用値を保持して断面を選ぶ。
x0 = xvar;
if is_pure_lsr
  secdim = secmgr.findNearestSection(xvar, options);
  xvar = secmgr.findNearestXvar(secdim, options);
end
if do_restration
  % xvar_ = restore_girder_height_gap(xvar, secdim, secmgr, options);
  xvar_ = restore_girder_height_gap_ip(xvar, 0, secmgr, isvar, options);
  if size(xvar_,1)>1
    id = randi(size(xvar_,1));
    xvar = xvar_(id,:);
  end
end

% 制約評価（構造解析）
% restoration 後の xvar に対応する断面を1回だけ写像し、制約評価と
% 目的関数評価で共有する（_xvar ラッパ内の二重写像を避ける）
secdim = secmgr.findNearestSection(xvar, options);
com = update_frame_data(secdim, com, options);
cvec = analysis_constraint(xvar, secdim, com, options);
fval = objective_lsr(secdim, secmgr, com.node, com.section, ...
  com.member, com.floor);
cache = initialize_cache();
save_cache(xvar, fval, cvec);
if ~isempty(resume_rng_state)
  rng(resume_rng_state);
end

% --- パラメータ設定 ---
tau = options.tau;
omega = options.omega;
ncon = com.ncon;
nc = length(cvec);
% nvio = length(ncon);
nvio = nc;

mx = size(xvar,2);
clabel = com.conlabel;

% --- ペナルティ係数設定 ---
muvec = mu*ones(nvio, 1);
resume_index = [];
last_history_index = 0;
% isupdatedmu = false;
is_output_best_point = true;
% if options.idphase == 2
%   is_output_best_point = false;
% else
%   is_output_best_point = true;
% end

% --- ペナルティ関数評価 ---
penalty_method = options.penalty_method;
pffun = @(f,c) calc_penalty(f,c,muvec,tau,penalty_method,ppp);
[pfval, vio] = pffun(fval, cvec);
% 比較基準になる前回点の初期値（入れ子関数と共有する）
xold = xvar;
fvalold = fval;
cvecold = cvec;
nexec = 1;
iter = 1;
nlist0 = 1;
nlist = 1;
idpfval = 1;
lsfr_history_info = struct('algorithm', nan, 'error_percent', nan, ...
  'depth', 0);
% isupdatedmu = false;

%---
options.numc = nc;
options.numvio = nvio;
time = toc;

% --- 履歴変数準備 ---
if isempty(history)
  history = inialize_history();
  start_iter = 0;
  save_initial_state();
  print_status(start_iter);
else
  validate_resume_history();
  history = ensure_lsr_history_info(history);
  resume_index = history_index_by_iter(options.iter_resume);
  history = trim_history(history, resume_index);
  start_iter = options.iter_resume;
  last_history_index = resume_index;
  restore_current_state(resume_index);
  restore_previous_state(start_iter);
  % 復元した係数で現在点を評価し直す。履歴の pf・vio は記録として扱う
  refresh_pffun();
  [pfval, vio] = pffun(fval, cvec);
end
history = ensure_lsr_history_info(history);
exitflag = PRM.EXITFLAG_MAXITER;

% ---　局所探索スタート ---
for iter = start_iter+1:max_iter+1
  previous_iter = iter-1;
  if previous_iter > 0 && postprocess_iteration(previous_iter)
    break
  end
  if iter > max_iter
    break
  end
  options.iter = iter;
  time_neighborhood = nan;
  time_correction = nan;
  time_evaluation = nan;

  % デバッグ用
  % if iter==23 && options.idphase == 2
  % if iter==17
  %   options.do_parallel = false;
  % end

  % 採否と係数更新は、採択時に保存したfvalとcvecを基準にする。
  % 再解析では詳細結果だけを取得し、比較基準の丸め差を持ち込まない。
  secdim = secmgr.findNearestSection(xvar, options);
  com = update_frame_data(secdim, com, options);
  member = com.member;
  idmc2m = member.column.idme;
  idm2n = [member.property.idnode1 member.property.idnode2];
  mtype = member.property.type;
  cgsr = com.cgsr;
  Dgap = com.Dgap;
  [~, result, restoration] = analysis_constraint(xvar, secdim, com, ...
    options);
  cxl = result.cxl;
  % st = restoration.st;
  % stc = restoration.stc;
  % C = restoration.C;
  vix = restoration.vix;
  viy = restoration.viy;

  % [~, ~, ~, ~, st, stc, ~, C, vix, viy] = ...
  %   analysis_frame(secdim, com, options);

  if do_lsfr
    [xlist, pflist, flist, clist, vlist, isexec, nlist0, ...
      lsfr_history_info] = lsfr_iteration(xvar, fval, cvec, result, ...
      restoration, pffun, @update_lsfr_penalty_values, com, options);
    nlist = size(xlist, 1);
  else
    % --- 近傍解生成 ---
    if collect_lsr_timing
      stage_timer = tic;
    end
    initial_guess = struct('x', xvar, 'secdim', result.secdim);
    [xlist, idvlist, sdlist] = secmgr.generateNeighborhoodSet( ...
      xvar, isvar, options, initial_guess, com);
    x_neighborhood = xlist;
    sd_neighborhood = sdlist;
    if collect_lsr_timing
      time_neighborhood = toc(stage_timer);
    end
    nlist0 = size(xlist,1);
    if collect_lsr_timing
      correction_timer = tic;
    end
    if do_restration
      % xlist = secmgr.findNearestXList(xlist, options);
      % xlist = unique(xlist, 'rows', 'stable');
      % nlist0 = size(xlist,1);

      % 梁せい差
      if consider_girder_height_gap
        xlist_ggap = restore_girder_height_gap_ip(xlist, idvlist, ...
          secmgr, isvar, options);
      else
        xlist_ggap = [];
      end

      % 梁せい分布の平滑化
      if consider_girder_height_smooth
        xlist_gsm = restore_girder_height_smooth(xlist, idvlist, ...
          secmgr, com.height_smooth, isvar, options);
      else
        xlist_gsm = [];
      end

      % 柱外径差
      if consider_column_diameter_gap
        xlist_cgap = restore_column_diameter_gap(xlist, Dgap, secmgr, ...
          isvar, options);
      else
        xlist_cgap = [];
      end

      % 細長比・幅厚比の修正
      if consider_slenderness_ratio && ~options.do_limit_slr_section
        xlist_slr = restore_girder_slratio(xvar, member, matF, ...
          restoration, secmgr, options);
      else
        xlist_slr = xvar;
      end

      % 仕口の保有耐力接合の修正
      % do_limit_jbs_section は保守的な section 事前フィルタであり、
      % 実行時の violation を完全に排除できないため restore は常に
      % 走らせる。
      if consider_joint_bearing_strength
        isjbs_ = com.exclusion.is_joint_bearing_strength;
        xlist_jbs = restore_joint_bearing_strength( ...
          xvar, member, matF, matGrade, secmgr, options, ...
          isjbs_, com.nominal.girder);
      else
        xlist_jbs = [];
      end

      % % --- 確認用 ---
      % fval_ = objfun(xlist_slratio);
      % cvec_ = analysis_constraint(xlist_slratio, com, options);
      % pfval_ = pffun(fval_, cvec_);
      % [maxvio_, idmaxvio_, idmaxvioc_, ccategory_] = ...
      %   extract_convio(ncon, ccon, tau, cvec_);
      % fprintf(['Iter:%4d pf:%6.2f f:%6.2f ' ...
      %   '(%d/%d->%d) c:%6.3f mu:%6.1f '], ...
      %   iter, pfval_, fval_, nlist0, nlist, 0, maxvio_, max(muvec));
      % fprintf('idvio:%4d（%s:%d） time:%f\n', ...
      %   idmaxvio_, ccategory_, idmaxvioc_, toc);
      % % ----

      % 柱梁耐力比 -> B,Dの修正
      % xlist_slr は slr スキップ時でも xvar を含むため常に非空。
      n_cgsr_in = size(xlist_slr, 1);
      cgsr_sdlist = zeros(size(result.secdim, 1), size(result.secdim, ...
        2), n_cgsr_in);
      use_worker_cache = options.do_parallel && isa(com.constant, ...
        'parallel.pool.Constant');
      if use_worker_cache
        worker_com_cache = com.constant;
        parfor il = 1:n_cgsr_in
          worker_com = worker_com_cache.Value; %#ok<PFBNS>
          cgsr_sdlist(:, :, il) = worker_com.secmgr.findNearestSection( ...
            xlist_slr(il, :), options, initial_guess);
        end
      elseif options.do_parallel
        parfor il = 1:n_cgsr_in
          cgsr_sdlist(:, :, il) = secmgr.findNearestSection( ...
            xlist_slr(il, :), options, initial_guess); %#ok<PFBNS>
        end
      else
        for il = 1:n_cgsr_in
          cgsr_sdlist(:, :, il) = secmgr.findNearestSection( ...
            xlist_slr(il, :), options, initial_guess);
        end
      end
      xlist_cgsr = restore_cgstrength_ratio(xlist_slr, cgsr_sdlist, ...
        vix, viy, cgsr, idm2n, idmc2m, member.property.idsec, ...
        mtype, matF, cxl, secmgr, options);

      % % --- 確認用 ---
      % fval_ = objfun(xlist_cgsr);
      % cvec_ = analysis_constraint(xlist_cgsr, com, options);
      % pfval_ = pffun(fval_, cvec_);
      % [maxvio_, idmaxvio_, idmaxvioc_, ccategory_] = ...
      %   extract_convio(ncon, ccon, tau, cvec_);
      % fprintf(['Iter:%4d pf:%6.2f f:%6.2f ' ...
      %   '(%d/%d->%d) c:%6.3f mu:%6.1f '], ...
      %   iter, pfval_, fval_, nlist0, nlist, 0, maxvio_, max(muvec));
      % fprintf('idvio:%4d（%s:%d） time:%f\n', ...
      %   idmaxvio_, ccategory_, idmaxvioc_, toc);
      % % ---

      % 幅厚比と群種別は現在点から生成し、写像済みの組を維持する。
      xlist_wt = zeros(0, numel(xvar));
      sdlist_wt = result.secdim(:, :, []);
      xlist_group = zeros(0, numel(xvar));
      sdlist_group = result.secdim(:, :, []);
      if copts.consider_section_wt_ratio || copts.consider_group_rank
        [grank, crank, is_wtcon] = get_wtratio_requirements(com, options);
        [Fs, isSNsec] = get_section_material_properties( ...
          result.secdim, com);
        [xlist_wt, sdlist_wt, conwt, drank] = restore_section_wtratio( ...
          xvar, result.secdim, com, options, Fs, isSNsec, ...
          grank, crank, is_wtcon);
        [xlist_group, sdlist_group] = restore_group_rank(xvar, ...
          result.secdim, result.Qm, com, options, conwt, drank, ...
          Fs, isSNsec, grank, crank, is_wtcon);
      end
      % 近傍集合は反復ごとに再生成するため累積しない。
      x_neighborhood = [x_neighborhood; xlist_wt; xlist_group]; %#ok<AGROW>
      sd_neighborhood = cat(3, sd_neighborhood, sdlist_wt, sdlist_group);

      % 候補解集合の追加
      xlist  = [xlist; xlist_ggap; xlist_gsm; xlist_cgap; ...
        xlist_slr; xlist_jbs; xlist_cgsr; ...
        xlist_wt; xlist_group]; %#ok<AGROW>
      xlist = unique(xlist, 'rows', 'stable');

      % xlist = secmgr.findNearestXList(xlist, options);
      % xlist  = unique(xlist, 'rows', 'stable');
    end

  nlist = size(xlist,1);
  % xlist0 = xlist;
  xlist(:,~isvar) = repmat(x0(~isvar), nlist, 1);
  [is_reused, reuse_index] = ismember(xlist, x_neighborhood, 'rows');
  candidate_sdlist = zeros(size(result.secdim, 1), size(result.secdim, ...
    2), nlist);
  candidate_sdlist(:, :, is_reused) = sd_neighborhood(:, :, ...
    reuse_index(is_reused));
  if any(~is_reused)
    missing_sdlist = secmgr.findNearestSectionList( ...
      xlist(~is_reused, :), options, initial_guess, com);
    candidate_sdlist(:, :, ~is_reused) = missing_sdlist;
  end
  sdlist = candidate_sdlist;
  if collect_lsr_timing
    time_correction = toc(correction_timer);
  end

  % 設計解の評価
  if collect_lsr_timing
    stage_timer = tic;
  end
  [pflist, flist, clist, vlist, isexec] = compute_pflist(pffun, xlist, ...
    sdlist, com, options, cache);
  if collect_lsr_timing
    time_evaluation = toc(stage_timer);
  end
  save_cache()
  end
  nexec = nexec + sum(isexec);

  [xvar, pfval, idpfval] = select_minpf(xlist, pflist);
  vio = vlist(idpfval,:);
  cvec = clist(idpfval,:);
  fval = flist(idpfval);

  % 履歴保存
  time = toc;
  save_history();
  print_status(iter);
end

if last_history_index > 0
  iter = history.iter(last_history_index);
else
  iter = 0;
end

time = toc;
finalize_history();
hist_x = history.xvar;
hist_f = history.fval;
hist_v = history.vio;
[xopt, ~, fopt, vopt] = find_best_point(hist_x, hist_f, hist_v);
maxvio = max(vopt);%
fprintf(1,'\t 目的関数値:%6.1f 違反量:%6.3f 計算時間:%6.1f[sec])\n', ...
  fopt, maxvio, time);
% history.time = time;
% history.iter = iter;
history.maxvio = maxvio;
% history.cvec = cvec;

% xopt
% xopt(secmgr.idsrep2var(secmgr.idsrep2stype==PRM.WFS,1:4))
% xopt(secmgr.idsrep2var(secmgr.idsrep2stype==PRM.HSS,1:2))
return
%--------------------------------------------------------------------------
  function print_status(iter)
  %print_status - 現在の反復の評価値と制約違反を表示する
  %
  %   print_status(iter) は、
  %   現在の反復の評価値と制約違反を表示する。
  %
  %   入力引数:
  %     iter - 現在の反復番号
  %     （外側の ncon, clabel, tau, cvec, vio, ppp, display_mode,
  %     is_pure_lsr, pfval, fval, nlist0, nlist, idpfval, muvec,
  %     lsfr_history_info を参照）
  %
  %   出力引数:
  %     なし

    [maxvio, idmaxvio, idmaxvioc, ccategory] = extract_convio(ncon, ...
      clabel, tau, cvec);
    % 表示用の違反量ノルム。calc_penalty が返した vio をそのまま使う
    vnorm = sum(vio.^ppp,2)^(1/ppp);
    switch(display_mode)
      case 'Iter'
        if is_pure_lsr
          fargs = {iter, pfval, fval, nlist0, nlist, idpfval, ...
            maxvio, vnorm, max(muvec)};
          fprintf(['Iter:%4d pf:%6.2f f:%6.2f (%d/%d->%d) ' ...
            'cmax:%6.3f vnorm:%6.3f mu:%6.1f '], fargs{:});
        else
          fargs = {iter, pfval, fval, nlist0, nlist, idpfval, maxvio};
          fprintf(['Iter:%4d pf:%6.2f f:%6.2f (%d/%d->%d) ' ...
            'cmax:%6.3f '], fargs{:});
          if isnan(lsfr_history_info.error_percent)
            fprintf('err: ---%% dep:%d ', lsfr_history_info.depth);
          else
            fprintf('err:%4.1f%% dep:%d ', ...
              lsfr_history_info.error_percent, lsfr_history_info.depth);
          end
          fprintf('mu:%6.1f ', max(muvec));
        end
        fprintf('idvio:%4d（%s:%d） time:%f\n', idmaxvio, ccategory, ...
          idmaxvioc, toc);
      case 'Iter10'
        fprt_ = sprintf('%6.1f', fval);
        cprt_ = sprintf('%6.3f', maxvio);
        if iter==0
          fprintf(1,'%s(%s:%s)', fprt_, ccategory, cprt_)
        end
        if mod(iter-1,10)==0
          fprintf(1,'->%s(%s:%s)', fprt_, ccategory, cprt_)
        end
      otherwise
    end

    return
  end
%--------------------------------------------------------------------------
% function muvec = initialize_muvec(mu)
%   idc2 = cumsum(ncon);
%   idc1 = [1 idc2(1:nvio-1)+1];
%   muvec = ones*(nvio,1);
%   for i=1:nvio
%     vio(i) = max(cvec(idc1(i):idc2(i)));
%   end
% end
%--------------------------------------------------------------------------
  function muvec = update_muvec(muvec, r, vio)
  %update_muvec - 違反が残る制約のペナルティ係数を r 倍する
  %
  %   muvec = update_muvec(muvec, r, vio) は、違反量が正の制約の
  %   係数だけを r 倍して返す。
  %
  %   入力引数:
  %     muvec - 更新前のペナルティ係数 [nc×1]
  %     r     - 係数の倍率
  %     vio   - 現在点の制約違反量 [1×nc]（充足は0）
  %
  %   出力引数:
  %     muvec - 更新後のペナルティ係数 [nc×1]

    muvec(vio > 0) = r*muvec(vio > 0);

    return
  end
%--------------------------------------------------------------------------
  function refresh_pffun
  %refresh_pffun - 現在のペナルティ係数で評価関数を作り直す
  %
  %   refresh_pffun() は、係数 muvec を変えた直後に呼び、以後の候補
  %   評価と比較基準の再評価が同じ係数を使うようにする。
  %
  %   入力引数:
  %     なし（外側の muvec・tau・penalty_method・ppp を参照）
  %
  %   出力引数:
  %     なし（外側の pffun を更新）

    pffun = @(f,c) calc_penalty(f,c,muvec,tau,penalty_method,ppp);

    return
  end
%--------------------------------------------------------------------------
  function [pflist_, vlist_, old_muvec_, new_muvec_] = ...
      update_lsfr_penalty_values(flist_, clist_, current_vio_)
  %update_lsfr_penalty_values - LSFR候補PFを更新後係数で再計算する
  %
  %   [pflist_, vlist_, old_muvec_, new_muvec_] = ...
  %     update_lsfr_penalty_values(flist_, clist_, current_vio_) は、
  %   外側のmuvecとpffunを更新し、保存済みの候補値を再評価する。
  %
  %   入力引数:
  %     flist_, clist_ - 保存済みの候補目的関数値と制約値
  %     current_vio_ - 現在点の制約違反量
  %
  %   出力引数:
  %     pflist_, vlist_ - 更新後の候補PFと制約違反量
  %     old_muvec_, new_muvec_ - 更新前後のペナルティ係数

    old_muvec_ = muvec;
    muvec = update_muvec(muvec, r, current_vio_);
    refresh_pffun();
    candidate_count_ = size(flist_, 1);
    pflist_ = zeros(candidate_count_, 1);
    vlist_ = zeros(size(clist_));
    for candidate_index_ = 1:candidate_count_
      [pflist_(candidate_index_), vlist_(candidate_index_, :)] = ...
        pffun(flist_(candidate_index_), clist_(candidate_index_, :));
    end
    new_muvec_ = muvec;

    return
  end
%--------------------------------------------------------------------------
  function [x, pfval, fval, vio, id] = find_best_point(...
      xlist, flist, violist)
  %find_best_point - 候補の目的関数値と違反量から採択点を選ぶ
  %
  %   [x, pfval, fval, vio, id] = find_best_point(...
  %   xlist, flist, violist) は、
  %   候補の目的関数値と違反量から採択点を選ぶ。
  %
  %   入力引数:
  %     xlist - 候補の設計変数配列
  %     flist - 候補別の目的関数値
  %     violist - 候補別の制約違反量
  %     （外側の is_output_best_point を参照）
  %
  %   出力引数:
  %     x - 設計変数ベクトル
  %     pfval - ペナルティ付き目的関数値
  %     fval - 目的関数値
  %     vio - 制約違反量
  %     id - 採択した候補の行番号

    pflist_ = flist(:)+1e8*max(violist,[],2);
    if is_output_best_point
      [~, id] = min(pflist_);
    else
      id = length(pflist_);
    end
    pfval = pflist_(id);
    x = xlist(id,:);
    fval= flist(id);
    vio = violist(id,:);

    return
  end
%--------------------------------------------------------------------------
  function cache = initialize_cache
  %initialize_cache - 実評価結果を保存するキャッシュを初期化する
  %
  %   cache = initialize_cache は、
  %   実評価結果を保存するキャッシュを初期化する。
  %
  %   入力引数:
  %     なし
  %
  %   出力引数:
  %     cache - 評価済み候補のキャッシュ

    % 実行結果キャッシュ初期化
    cache = struct('xlist',[],'clist',[],'flist',[]);

    return
  end
%--------------------------------------------------------------------------
  function save_cache(xlist_, flist_, clist_)
  %save_cache - 新しく評価した候補をキャッシュへ保存する
  %
  %   save_cache(xlist_, flist_, clist_) は、
  %   新しく評価した候補をキャッシュへ保存する。
  %
  %   入力引数:
  %     xlist_ - 保存対象の設計変数配列
  %     flist_ - 保存対象の目的関数値
  %     clist_ - 保存対象の制約値
  %     （外側の options, xlist, flist, clist, isexec を参照）
  %
  %   出力引数:
  %     なし（外側の cache を更新）

    if nargin==0
      xlist_ = xlist;
      flist_ = flist;
      clist_ = clist;
      isexec_ = isexec;
    else
      isexec_ = true(1,length(xlist_));
    end

    % 実行結果キャッシュ保存
    if options.do_cache
      if isempty(cache.xlist)
        cache.xlist = xlist_;
        cache.flist = flist_;
        cache.clist = clist_;
      else
        nlist_ = sum(isexec_);
        ncache = size(cache.xlist,1);
        if ncache+nlist_>options.maxcache
          nnn = ncache+nlist_-options.maxcache+1;
        else
          nnn = 1;
        end
        cache.xlist = [cache.xlist(nnn:end,:); xlist_(isexec_,:)];
        cache.flist = [cache.flist(nnn:end); flist_(isexec_)];
        cache.clist = [cache.clist(nnn:end,:); clist_(isexec_,:)];
      end
    end

    return
  end
%--------------------------------------------------------------------------
  function history = inialize_history
  %inialize_history - 探索反復の履歴配列を初期化する
  %
  %   history = inialize_history は、
  %   探索反復の履歴配列を初期化する。
  %
  %   入力引数:
  %     なし（外側の max_iter, mx, nc, nvio を参照）
  %
  %   出力引数:
  %     history - 探索反復の履歴

    history = struct;
    history.initial = struct;
    history.xvar = zeros(max_iter,mx);
    history.fval = zeros(max_iter,1);
    history.cvec = zeros(max_iter,nc);
    history.pf = zeros(max_iter,1);
    history.muvec = zeros(max_iter,nc);
    history.mu = zeros(max_iter,nc);
    history.vio = zeros(max_iter,nvio);
    history.sa_aborted = false(max_iter,1);
    history.nexec = zeros(max_iter,1);
    history.time = zeros(max_iter,1);
    history.iter = zeros(max_iter,1);

    return
  end
%--------------------------------------------------------------------------
  function validate_resume_history
  %validate_resume_history - 再開に必要な履歴と反復番号を検証する
  %
  %   validate_resume_history は、
  %   再開に必要な履歴と反復番号を検証する。
  %
  %   入力引数:
  %     なし（外側の options, history を参照）
  %
  %   出力引数:
  %     なし

    if options.iter_resume < 1
      error('lsr:InvalidResumeIter', ...
        'Resume iter must be greater than or equal to 1.');
    end
    names = {'initial','muvec','sa_aborted'};
    for i = 1:numel(names)
      if ~isfield(history, names{i})
        error('lsr:InvalidResumeHistory', ...
          'Resume history does not contain %s.', names{i});
      end
    end
    return
  end
%--------------------------------------------------------------------------
  function row = history_index_by_iter(target_iter)
  %history_index_by_iter - 反復番号に対応する履歴行を求める
  %
  %   row = history_index_by_iter(target_iter) は、
  %   反復番号に対応する履歴行を求める。
  %
  %   入力引数:
  %     target_iter - 取得する反復番号
  %     （外側の history を参照）
  %
  %   出力引数:
  %     row - 対応する履歴行

    row = find(history.iter == target_iter);
    if numel(row) ~= 1
      msg = 'Resume iter %d does not exist.';
      error('lsr:ResumeIterNotFound', msg, target_iter);
    end
    return
  end
%--------------------------------------------------------------------------
  function history = trim_history(history, last_index)
  %trim_history - 指定行より後の履歴を削除する
  %
  %   history = trim_history(history, last_index) は、
  %   指定行より後の履歴を削除する。
  %
  %   入力引数:
  %     history - 探索反復の履歴
  %     last_index - 最後に残す履歴行
  %
  %   出力引数:
  %     history - 探索反復の履歴

    history.xvar = history.xvar(1:last_index,:);
    history.fval = history.fval(1:last_index,:);
    history.cvec = history.cvec(1:last_index,:);
    history.vio = history.vio(1:last_index,:);
    history.pf = history.pf(1:last_index,:);
    history.muvec = history.muvec(1:last_index,:);
    history.mu = history.muvec;
    history.sa_aborted = history.sa_aborted(1:last_index,:);
    history.nexec = history.nexec(1:last_index,:);
    history.time = history.time(1:last_index,:);
    history.iter = history.iter(1:last_index,:);
    history = trim_history_info(history, last_index);
    return
  end
%--------------------------------------------------------------------------
  function save_initial_state
  %save_initial_state - 初期評価点とペナルティ係数を履歴へ保存する
  %
  %   save_initial_state は、
  %   初期評価点とペナルティ係数を履歴へ保存する。
  %
  %   入力引数:
  %     なし（外側の xvar, fval, cvec, vio, pfval, muvec, nexec,
  %     time を参照）
  %
  %   出力引数:
  %     なし（外側の history.initial を更新）

    history.initial.xvar = xvar;
    history.initial.fval = fval;
    history.initial.cvec = cvec;
    history.initial.vio = vio;
    history.initial.pf = pfval;
    history.initial.muvec = muvec;
    history.initial.mu = muvec;
    history.initial.nexec = nexec;
    history.initial.time = time;

    return
  end
%--------------------------------------------------------------------------
  function restore_current_state(row)
  %restore_current_state - 指定履歴行から現在の評価点と係数を復元する
  %
  %   restore_current_state(row) は、
  %   指定履歴行から現在の評価点と係数を復元する。
  %
  %   入力引数:
  %     row - 対応する履歴行
  %     （外側の history を参照）
  %
  %   出力引数:
  %     なし（外側の xvar, fval, cvec, muvec, nexec, time を更新）

    xvar = history.xvar(row,:);
    fval = history.fval(row,1);
    cvec = history.cvec(row,:);
    muvec = history.muvec(row,:)';
    nexec = history.nexec(row,1);
    time = history.time(row,1);

    return
  end
%--------------------------------------------------------------------------
  function restore_previous_state(current_iter)
  %restore_previous_state - 指定反復の直前の評価点を復元する
  %
  %   restore_previous_state(current_iter) は、
  %   指定反復の直前の評価点を復元する。
  %
  %   入力引数:
  %     current_iter - 再開する反復番号
  %     （外側の history を参照）
  %
  %   出力引数:
  %     なし（外側の xold, fvalold, cvecold を更新）

    if current_iter == 1
      xold = history.initial.xvar;
      fvalold = history.initial.fval;
      cvecold = history.initial.cvec;
      return
    end
    old_index = history_index_by_iter(current_iter-1);
    xold = history.xvar(old_index,:);
    fvalold = history.fval(old_index,1);
    cvecold = history.cvec(old_index,:);
    return
  end
%--------------------------------------------------------------------------
  function tf = postprocess_iteration(processed_iter)
  %postprocess_iteration - 反復結果を採択して係数と前回点を更新する
  %
  %   tf = postprocess_iteration(processed_iter) は、
  %   反復結果を採択して係数と前回点を更新する。
  %
  %   入力引数:
  %     processed_iter - 処理対象の反復番号
  %     （外側の pffun, fvalold, cvecold, vio, pfval, omega, options,
  %     max_iter, muvec, r, is_pure_lsr, xold, resume_index, start_iter,
  %     history を参照）
  %
  %   出力引数:
  %     tf - 判定結果
  %     （外側の exitflag, do_restration, xvar, fval, cvec, vio,
  %     pfval, muvec, pffun, history, xold, fvalold, cvecold を更新）

    tf = false;

    % 前回点を現在の係数で再評価し、候補と同じ係数で比較する
    [pfvalold, viold] = pffun(fvalold, cvecold);

    % --- 終了判定 ---
    if all(vio<=0) && pfval-pfvalold>=omega && all(viold<=0)
      exitflag = PRM.EXITFLAG_CONVERGED;
      tf = true;
      return
    end

    % --- 関数値が改良されないときの処理 ---
    if pfval-pfvalold >= omega
      % if (pfval-pfvalold < 1 && ~isupdatedmu) ...
      %     && (vnorm-vnormold>=-0.01 && any(vio>0))
      % if fval-fold>=omega || (vnorm-vnormold>=-0.001 && any(vio>0))
      do_restration = options.do_restration;
      is_aborted = ~options.do_SA;
      % SA
      if options.do_SA
        if should_reuse_sa_aborted(processed_iter)
          is_aborted = read_sa_aborted(processed_iter);
        else
          temprature = processed_iter/max_iter;
          prob = 1-temprature;
          rrr = rand;
          %fprintf([' dpf:%f t:%f r:%f p:%f'], ...
          %  pfval-pfvalold, temprature, rrr, prob)
          if rrr>prob
            is_aborted = true;
            %fprintf(' Aborted.\n')
          else
            %fprintf(' \n')
          end
          save_sa_aborted(processed_iter, is_aborted);
        end
      end

      % 更新を破棄
      if is_aborted
        xvar = xold;
        fval = fvalold;
        cvec = cvecold;
        vio = viold;
        pfval = pfvalold;
      end

      %[x0, pfval, id] = find_best_point(history.f, ...
      %  history.violation, muvec);
      %violation = violist(id,:);
      %cvec = clist(id,:);
      %

      % if(max(muvec)>1e3)
      %   penalty_method = PRM.PENALTY_MAXIMUM;
      % end

      % 許容解が見つからないので打ち切り
      if(max(muvec)>1e8)
        %violation = violist(id,:);
        %cvec = clist(id,:);
        tf = true;
        return
      end

      % 違反が残る制約の係数を増やし、次反復の候補評価と比較に反映する
      if is_pure_lsr
        muvec = update_muvec(muvec, r, vio);
        refresh_pffun();
      end
    end

    update_old_state();
    return
  end
%--------------------------------------------------------------------------
  function tf = should_reuse_sa_aborted(processed_iter)
  %should_reuse_sa_aborted - 焼きなましの中断状態の引継ぎを判定する
  %
  %   tf = should_reuse_sa_aborted(processed_iter) は、
  %   再開時に焼きなましの中断状態を引き継ぐか判定する。
  %
  %   入力引数:
  %     processed_iter - 処理対象の反復番号
  %     （外側の resume_index, start_iter を参照）
  %
  %   出力引数:
  %     tf - 判定結果

    tf = ~isempty(resume_index) && processed_iter == start_iter;
    return
  end
%--------------------------------------------------------------------------
  function is_aborted = read_sa_aborted(processed_iter)
  %read_sa_aborted - 指定反復の焼きなまし中断状態を取得する
  %
  %   is_aborted = read_sa_aborted(processed_iter) は、
  %   指定反復の焼きなまし中断状態を取得する。
  %
  %   入力引数:
  %     processed_iter - 処理対象の反復番号
  %     （外側の history を参照）
  %
  %   出力引数:
  %     is_aborted - 焼きなましが中断されたかどうか

    row = history_index_by_iter(processed_iter);
    is_aborted = history.sa_aborted(row,1);
    return
  end
%--------------------------------------------------------------------------
  function save_sa_aborted(processed_iter, is_aborted)
  %save_sa_aborted - 指定反復の焼きなまし中断状態を保存する
  %
  %   save_sa_aborted(processed_iter, is_aborted) は、
  %   指定反復の焼きなまし中断状態を保存する。
  %
  %   入力引数:
  %     processed_iter - 処理対象の反復番号
  %     is_aborted - 焼きなましが中断されたかどうか
  %     （外側の history を参照）
  %
  %   出力引数:
  %     なし（外側の history.sa_aborted を更新）

    row = history_index_by_iter(processed_iter);
    history.sa_aborted(row,1) = is_aborted;
    return
  end
%--------------------------------------------------------------------------
  function update_old_state
  %update_old_state - 現在の評価点を次反復の前回点として保存する
  %
  %   update_old_state は、
  %   現在の評価点を次反復の前回点として保存する。
  %
  %   入力引数:
  %     なし（外側の xvar, cvec, fval を参照）
  %
  %   出力引数:
  %     なし（外側の xold, cvecold, fvalold を更新）

    xold = xvar;
    cvecold = cvec;
    fvalold = fval;
    return
  end
%--------------------------------------------------------------------------
  function save_history
  %save_history - 現在の反復結果と診断値を履歴へ保存する
  %
  %   save_history は、
  %   現在の反復結果と診断値を履歴へ保存する。
  %
  %   入力引数:
  %     なし（外側の iter, xvar, fval, cvec, vio, pfval, muvec, nexec,
  %     time, time_neighborhood, time_correction, time_evaluation,
  %     lsfr_history_info を参照）
  %
  %   出力引数:
  %     なし（外側の history, last_history_index を更新）

    history.xvar(iter,:) = xvar;
    history.fval(iter,1) = fval;
    history.cvec(iter,:) = cvec;
    history.vio(iter,:) = vio;
    history.pf(iter,1) = pfval;
    history.muvec(iter,:) = muvec;
    history.mu(iter,:) = muvec;
    history.sa_aborted(iter,1) = false;
    history.nexec(iter,1) = nexec;
    history.time(iter,1) = time;
    history.iter(iter,1) = iter;
    info_row = struct;
    info_row.lsr.timing = struct('neighborhood', time_neighborhood, ...
      'correction', time_correction, 'evaluation', time_evaluation);
    info_row.lsfr.selection = lsfr_history_info;
    history = save_history_info(history, info_row, iter);
    last_history_index = iter;

    return
  end
%--------------------------------------------------------------------------
  function finalize_history
  %finalize_history - 有効な最終反復まで履歴を切り詰める
  %
  %   finalize_history は、
  %   有効な最終反復まで履歴を切り詰める。
  %
  %   入力引数:
  %     なし（外側の history, last_history_index を参照）
  %
  %   出力引数:
  %     なし（外側の history を更新）

    history.xvar = history.xvar(1:last_history_index,:);
    history.fval = history.fval(1:last_history_index,:);
    history.cvec = history.cvec(1:last_history_index,:);
    history.vio = history.vio(1:last_history_index,:);
    history.pf = history.pf(1:last_history_index,:);
    history.muvec = history.muvec(1:last_history_index,:);
    history.mu = history.muvec;
    history.sa_aborted = history.sa_aborted(1:last_history_index,:);
    history.nexec = history.nexec(1:last_history_index,:);
    history.time = history.time(1:last_history_index,:);
    history.iter = history.iter(1:last_history_index,:);
    history = trim_history_info(history, last_history_index);

    return
  end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
  function history_ = trim_history_info(history_, last_index_)
  %trim_history_info - 履歴内の診断値を指定行まで切り詰める
  %
  %   history_ = trim_history_info(history_, last_index_) は、
  %   履歴内の診断値を指定行まで切り詰める。
  %
  %   入力引数:
  %     history_ - 診断値を含む探索履歴
  %     last_index_ - 診断値を残す最終行
  %
  %   出力引数:
  %     history_ - 診断値を含む探索履歴

    if ~isfield(history_, 'info')
      return
    end
    schema = lsr_history_info_schema();
    for id_ = 1:numel(schema)
      m_ = schema(id_).method;
      c_ = schema(id_).category;
      for jd_ = 1:numel(schema(id_).fields)
        f_ = schema(id_).fields{jd_};
        values_ = history_.info.(m_).(c_).(f_);
        history_.info.(m_).(c_).(f_) = values_(1:last_index_, :);
      end
    end

    return
  end
%--------------------------------------------------------------------------
  function history_ = save_history_info(history_, info_row, iter_)
  %save_history_info - 一反復分の診断値を履歴へ格納する
  %
  %   history_ = save_history_info(history_, info_row, iter_) は、
  %   一反復分の診断値を履歴へ格納する。
  %
  %   入力引数:
  %     history_ - 診断値を含む探索履歴
  %     info_row - 一反復分の診断値
  %     iter_ - 保存先の反復番号
  %
  %   出力引数:
  %     history_ - 診断値を含む探索履歴

    schema = lsr_history_info_schema();
    for id_ = 1:numel(schema)
      m_ = schema(id_).method;
      c_ = schema(id_).category;
      for jd_ = 1:numel(schema(id_).fields)
        f_ = schema(id_).fields{jd_};
        history_.info.(m_).(c_).(f_)(iter_, 1) = info_row.(m_).(c_).(f_);
      end
    end

    return
  end
%--------------------------------------------------------------------------
end
