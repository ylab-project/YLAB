function [xopt, fopt, exitflag, history] = lsr(xvar, com, history, options)

tic;
% 共通定数
max_iter = options.maxiter_in_LS;
if ~isfinite(max_iter)
  max_iter = 200;
end
ppp = 3;

% ID配列
idmc2m = com.member.column.idme;
idm2n = [com.member.property.idnode1 com.member.property.idnode2];

% 共通配列
cgsr = com.cgsr;
Dgap = com.Dgap;
matF = com.material.F;
matGrade = com.material.steel_grade;
mdir = com.member.property.idir;
mtype = com.member.property.type;
secmgr = com.secmgr;
section = com.section;
member = com.member;
% member_girder = com.member.girder;
% member_property = com.member.girder;
baseline = com.baseline;
node = com.node;
story = com.story;
floor = com.floor;
isvar = com.design.variable.isvar;

% 条件設定
mu = options.mu;
r = options.r;
display_mode = options.display;
% max_iter = options.maxiter_in_LS;
do_restration = options.do_restration;
% do_parallel = options.do_parallel;
copts = options.coptions;
consider_girder_height_gap = ...
  copts.consider_girder_height_gap_var | ...
  copts.consider_girder_height_gap_section;
consider_girder_height_smooth = copts.consider_girder_height_smooth_var;
consider_column_diameter_gap = copts.consider_column_diameter_gap;
consider_slenderness_ratio = copts.consider_slenderness_ratio;
consider_joint_bearing_strength = copts.consider_joint_bearing_strength;
secmgr.idphase = options.idphase;

resume_rng_state = [];
if ~isempty(history)
  resume_rng_state = rng;
end

% 初期解の不整合除去
x0 = xvar;
secdim = secmgr.findNearestSection(xvar, options);
xvar = secmgr.findNearestXvar(secdim, options);
if do_restration
  % xvar_ = restore_girder_height_gap(xvar, secdim, secmgr, options);
  xvar_ = restore_girder_height_gap_ip(xvar, 0, secdim, secmgr, options);
  if size(xvar_,1)>1
    id = randi(size(xvar_,1));
    xvar = xvar_(id,:);
  end
end

% 制約評価（構造解析）
[cvec, result] = analysis_constraint(xvar, com, options);
fval = objfun(xvar);
cache = initialize_cache();
save_cache(xvar, fval, cvec);
if ~isempty(resume_rng_state)
  rng(resume_rng_state);
end

% --- パラメータ設定 ---
tau = options.tau;
omega = options.omega;
ncon = result.ncon;
nc = length(cvec);
% nvio = length(ncon);
nvio = nc;

mx = size(xvar,2);
clabel = result.conlabel;

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
xold = xvar;
fvalold = fval;
cvecold = cvec;
% pfvalold/viold は比較対象なしを表す番兵値。
pfvalold = inf;
viold = inf(size(vio));
nexec = 1;
iter = 1;
nlist0 = 1;
nlist = 1;
idpfval = 1;
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
  resume_index = history_index_by_iter(options.iter_resume);
  history = trim_history(history, resume_index);
  start_iter = options.iter_resume;
  last_history_index = resume_index;
  restore_current_state(resume_index);
  restore_previous_state(start_iter);
  pffun = @(f,c) calc_penalty(f,c,muvec,tau,penalty_method,ppp);
end
exitflag = PRM.EXITFLAG_MAXITER;

% --- 並列プール共有データの事前生成 ---
pool = gcp('nocreate');
if ~isempty(pool)
  com_constant = parallel.pool.Constant(com);
else
  com_constant = com;
end

% ---　局所探索スタート ---
for iter = start_iter+1:max_iter+1
  previous_iter = iter-1;
  if previous_iter == 0
    update_old_state();
  else
    if postprocess_iteration(previous_iter)
      break
    end
  end
  if iter > max_iter
    break
  end
  options.iter = iter;

  % デバッグ用
  % if iter==23 && options.idphase == 2
  % if iter==17
  %   options.do_parallel = false;
  % end

  % TODO 毎回解析するか要検討
  % 解析結果の更新
  [cvec, result, restoration] = analysis_constraint(xvar, com, options);
  cxl = result.cxl;
  % st = restoration.st;
  % stc = restoration.stc;
  % C = restoration.C;
  vix = restoration.vix;
  viy = restoration.viy;

  % [~, ~, ~, ~, st, stc, ~, C, vix, viy] = ...
  %   analysis_frame(xvar, com, options);

  % --- 近傍解生成 ---
  [xlist, idvlist] = secmgr.generateNeighborhoodSet(xvar, isvar, options);
  nlist0 = size(xlist,1);
  if do_restration
    % xlist = secmgr.findNearestXList(xlist, options);
    % xlist = unique(xlist, 'rows', 'stable');
    % nlist0 = size(xlist,1);
    sdlist = zeros(size(secdim,1), size(secdim,2), nlist0);
    if options.do_parallel
      parfor il=1:nlist0
        sdlist(:,:,il) = secmgr.findNearestSection(xlist(il,:), options);
      end
    else
      for il=1:nlist0
        sdlist(:,:,il) = secmgr.findNearestSection(xlist(il,:), options);
      end
    end

    % 梁せい差
    if consider_girder_height_gap
      xlist_ggap = restore_girder_height_gap_ip(...
        xlist, idvlist, sdlist, secmgr, options);
    else
      xlist_ggap = [];
    end

    % 梁せい分布の平滑化
    if consider_girder_height_smooth
      xlist_gsm = restore_girder_height_smooth(...
        xlist, idvlist, sdlist, secmgr, story.idvarH, options);
    else
      xlist_gsm = [];
    end

    % 柱外径差
    if consider_column_diameter_gap
      xlist_cgap = restore_column_diameter_gap(...
        xlist, sdlist, Dgap, secmgr, options);
    else
      xlist_cgap = [];
    end

    % 曲げ許容応力
    xlist_2 = [];
    % xlist_2 = restore_section_height(xvar, st, stc, C, com, options);
    % xlist_2 = restore_section_height(xlist, st, stc, C, com, options);

    % 細長比・幅厚比の修正
    if consider_slenderness_ratio && ~options.do_limit_slr_section
      xlist_slr = restore_girder_slratio(...
        xvar, member, matF, restoration, secmgr, options);
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
    cgsr_sdlist = zeros(size(secdim,1), size(secdim,2), n_cgsr_in);
    if options.do_parallel
      parfor il = 1:n_cgsr_in
        cgsr_sdlist(:,:,il) = ...
          secmgr.findNearestSection(xlist_slr(il,:), options);
      end
    else
      for il = 1:n_cgsr_in
        cgsr_sdlist(:,:,il) = ...
          secmgr.findNearestSection(xlist_slr(il,:), options);
      end
    end
    xlist_cgsr = restore_cgstrength_ratio(xlist_slr, cgsr_sdlist, ...
      vix, viy, cgsr, idm2n, idmc2m, mdir, mtype, matF, cxl, ...
      secmgr, options);

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

    % 候補解集合の追加
    xlist  = [xlist; ...
      xlist_ggap; xlist_gsm; xlist_cgap; xlist_2;  ...
      xlist_slr; xlist_jbs; xlist_cgsr];
    xlist = unique(xlist, 'rows', 'stable');

    % if iter<=inf
    %   xlist_ = restore_section_thickness(xlist, st, stc, C, ...
    %     com, options);
    %   xlist  = [xlist; xlist_];
    %   xlist  = unique(xlist, 'rows', 'stable');
    % end
    % xlist = secmgr.findNearestXList(xlist, options);
    % xlist  = unique(xlist, 'rows', 'stable');
  end

  nlist = size(xlist,1);
  % xlist0 = xlist;
  for il=1:nlist
    xlist(il,~isvar) = x0(~isvar);
  end

  % 設計解の評価
  [pflist, flist, clist, vlist, isexec] = ...
    compute_pflist(pffun, xlist, com_constant, options, cache);
  save_cache()
  nexec = nexec+sum(isexec);

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
% fopt_ = objfun(xopt);
cvec = analysis_constraint(xopt, com, options);
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
    [maxvio, idmaxvio, idmaxvioc, ccategory] = ...
      extract_convio(ncon, clabel, tau, cvec);
    vio = cvec;
    vio(vio<tau) = 0;
    vnorm = sum(vio.^ppp,2)^(1/ppp);
    switch(display_mode)
      case 'Iter'
        fargs = {iter, pfval, fval, nlist0, nlist, idpfval, ...
          maxvio, vnorm, max(muvec)};
        fprintf(['Iter:%4d pf:%6.2f f:%6.2f (%d/%d->%d) ' ...
          'cmax:%6.3f vnorm:%6.3f mu:%6.1f '], fargs{:});
        fprintf('idvio:%4d（%s:%d） time:%f\n', ...
          idmaxvio, ccategory, idmaxvioc, toc);
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
  end
%--------------------------------------------------------------------------
  function fval = objfun(xvar)
    fval = objective_lsr(xvar, secmgr, baseline, node, ...
      section, member, story, floor, options);
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
  function muvec = update_muvec(muvec, r, vio, tau)
    % [maxmu, imax] = max(muvec);
    for i = 1 : length(muvec)
      if vio(i)>tau
        muvec(i) = r*muvec(i);
      end
    end
  end
%--------------------------------------------------------------------------
  function [x, pfval, fval, vio, id] = find_best_point(...
      xlist, flist, violist)

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
    % 実行結果キャッシュ初期化
    cache = struct('xlist',[],'clist',[],'flist',[]);
  end
%--------------------------------------------------------------------------
  function save_cache(xlist_, flist_, clist_)
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
  end
%--------------------------------------------------------------------------
  function history = inialize_history
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
  end
%--------------------------------------------------------------------------
  function validate_resume_history
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
    row = find(history.iter == target_iter);
    if numel(row) ~= 1
      msg = 'Resume iter %d does not exist.';
      error('lsr:ResumeIterNotFound', msg, target_iter);
    end
    return
  end
%--------------------------------------------------------------------------
  function history = trim_history(history, last_index)
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
    return
  end
%--------------------------------------------------------------------------
  function save_initial_state
    history.initial.xvar = xvar;
    history.initial.fval = fval;
    history.initial.cvec = cvec;
    history.initial.vio = vio;
    history.initial.pf = pfval;
    history.initial.muvec = muvec;
    history.initial.mu = muvec;
    history.initial.nexec = nexec;
    history.initial.time = time;
  end
%--------------------------------------------------------------------------
  function restore_current_state(row)
    xvar = history.xvar(row,:);
    fval = history.fval(row,1);
    cvec = history.cvec(row,:);
    vio = history.vio(row,:);
    pfval = history.pf(row,1);
    muvec = history.muvec(row,:)';
    nexec = history.nexec(row,1);
    time = history.time(row,1);
  end
%--------------------------------------------------------------------------
  function restore_previous_state(current_iter)
    if current_iter == 1
      xold = history.initial.xvar;
      fvalold = history.initial.fval;
      cvecold = history.initial.cvec;
      viold = history.initial.vio;
      pfvalold = history.initial.pf;
      return
    end
    old_index = history_index_by_iter(current_iter-1);
    xold = history.xvar(old_index,:);
    fvalold = history.fval(old_index,1);
    cvecold = history.cvec(old_index,:);
    viold = history.vio(old_index,:);
    pfvalold = history.pf(old_index,1);
    return
  end
%--------------------------------------------------------------------------
  function tf = postprocess_iteration(processed_iter)
    tf = false;

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
      is_aborted = false;
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

      % ペナルティ係数更新法その１
      muvec = update_muvec(muvec, r, vio, tau);
      pffun = @(f,c) calc_penalty(f,c,muvec,tau,penalty_method,ppp);

      % % ペナルティ係数更新法その２
      % if isupdatedmu
      %   isupdatedmu = false;
      %   [~, idpfval] = min(max(vlist,[],2));
      %   xvar = xlist(idpfval,:);
      %   pfval = pflist(idpfval);
      %   vio = vlist(idpfval,:);
      %   cvec = clist(idpfval,:);
      %   fval = flist(idpfval);
      % else
      %   muvec = update_muvec(muvec, r, vio, tau);
      %   isupdatedmu = true;
      % end
    end

    update_old_state();
    return
  end
%--------------------------------------------------------------------------
  function tf = should_reuse_sa_aborted(processed_iter)
    tf = ~isempty(resume_index) && processed_iter == start_iter;
    return
  end
%--------------------------------------------------------------------------
  function is_aborted = read_sa_aborted(processed_iter)
    row = history_index_by_iter(processed_iter);
    is_aborted = history.sa_aborted(row,1);
    return
  end
%--------------------------------------------------------------------------
  function save_sa_aborted(processed_iter, is_aborted)
    row = history_index_by_iter(processed_iter);
    history.sa_aborted(row,1) = is_aborted;
    return
  end
%--------------------------------------------------------------------------
  function update_old_state
    viold = vio;
    pfvalold = pfval;
    xold = xvar;
    cvecold = cvec;
    fvalold = fval;
    return
  end
%--------------------------------------------------------------------------
  function save_history
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
    last_history_index = iter;
  end
%--------------------------------------------------------------------------
  function finalize_history
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
  end
%--------------------------------------------------------------------------
end

%==========================================================================
function [pfval, vio] = calc_penalty(fval, cvec, ...
  muvec, tau, penalty_method, ppp)
%calc_penalty - ペナルティ関数の評価
vio = cvec;
vio(vio<tau) = 0;
switch penalty_method
  case PRM.PENALTY_SUM_TOTAL
    pfval = fval+sum(vio(:).*muvec(:));
  case PRM.PENALTY_MAXIMUM
    vvv = sum(vio.^ppp,2)^(1/ppp);
    pfval = fval+max(muvec)*vvv;
end

return
end
