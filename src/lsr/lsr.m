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
% idmg2m = com.member.girder.idme;
idm2var = com.member.property.idvar;
idmc2sc = com.member.column.idsecc;
idmg2sg = com.member.girder.idsecg;
idm2n = [com.member.property.idnode1 com.member.property.idnode2];
% idncgsr = com.cgsr.idnode;

% 共通配列
cgsr = com.cgsr;
Dgap = com.Dgap;
% Fm = com.material.F(com.section.property.idmaterial(com.member.property.idsec));
matF = com.material.F;
lm = com.member.property.lm;
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
if isempty(history)
  muvec = mu*ones(nvio, 1);
else
  muvec = history.muvec(options.iter_resume,:)';
end
% isupdatedmu = false;
is_output_best_point = true;
% if options.idphase == 2
%   is_output_best_point = false;
% else
%   is_output_best_point = true;
% end

% --- ペナルティ関数評価 ---
penalty_method = options.penalty_method;
[pfval, vio] = pffun(fval, cvec);
xold = xvar;
pfvalold = pfval;
viold = vio;
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
else
  start_iter = options.iter_resume;
end
print_status(start_iter);
save_history();
exitflag = PRM.EXITFLAG_MAXITER;

% ---　局所探索スタート ---
for iter = start_iter+1:max_iter
  options.iter = iter;

  % デバッグ用
  % if iter==23 && options.idphase == 2
  % if iter==17
  %   options.do_parallel = false;
  % end

  % TODO 毎回解析するか要検討
  % 解析結果の更新
  [cvec, ~, restoration] = analysis_constraint(xvar, com, options);
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

    % % 細長比・幅厚比の修正
    if consider_slenderness_ratio && ~options.do_limit_slr_section
      xlist_slr = restore_girder_slratio(...
        xvar, member, matF, restoration, secmgr, options);
    else
      xlist_slr = [];
    end
    
    % % 仕口の保有耐力接合の修正
    if consider_joint_bearing_strength && ~options.do_limit_jbs_section
      xlist_jbs = restore_joint_bearing_strength(...
        xvar, member, matF, restoration, secmgr, options);
    else
      xlist_jbs = [];
    end

    % % --- 確認用 ---
    % fval_ = objfun(xlist_slratio);
    % cvec_ = analysis_constraint(xlist_slratio, com, options);
    % pfval_ = pffun(fval_, cvec_);
    % [maxvio_, idmaxvio_, idmaxvioc_, ccategory_] = ...
    %   extract_convio(ncon, ccon, tau, cvec_);
    % fprintf('Iter:%4d pf:%6.2f f:%6.2f (%d/%d->%d) c:%6.3f mu:%6.1f ', ...
    %   iter, pfval_, fval_, nlist0, nlist, 0, maxvio_, max(muvec));
    % fprintf('idvio:%4d（%s:%d） time:%f\n', ...
    %   idmaxvio_, ccategory_, idmaxvioc_, toc);
    % % ----

    % 柱梁耐力比 -> B,Dの修正
    % xlist_cgsr = restore_cgstrength_ratio(xvar, sdlist, vix, viy, ...
    %   cgsr, idm2n, idmc2m, idm2var, idmc2sc, idmg2sg, ...
    %   mdir, mtype, matF, secmgr, options);

    xlist_cgsr = restore_cgstrength_ratio(xlist_slr, sdlist, vix, viy, ...
      cgsr, idm2n, idmc2m, idm2var, idmc2sc, idmg2sg, ...
      mdir, mtype, matF, secmgr, options);

    % % --- 確認用 ---
    % fval_ = objfun(xlist_cgsr);
    % cvec_ = analysis_constraint(xlist_cgsr, com, options);
    % pfval_ = pffun(fval_, cvec_);
    % [maxvio_, idmaxvio_, idmaxvioc_, ccategory_] = ...
    %   extract_convio(ncon, ccon, tau, cvec_);
    % fprintf('Iter:%4d pf:%6.2f f:%6.2f (%d/%d->%d) c:%6.3f mu:%6.1f ', ...
    %   iter, pfval_, fval_, nlist0, nlist, 0, maxvio_, max(muvec));
    % fprintf('idvio:%4d（%s:%d） time:%f\n', ...
    %   idmaxvio_, ccategory_, idmaxvioc_, toc);
    % % ---

    % 候補解集合の追加
    xlist  = [xlist; ...
      xlist_ggap; xlist_gsm; xlist_cgap; xlist_2;  ...
      xlist_slr; xlist_jbs; xlist_cgsr];
    [xlist, ia, ic] = unique(xlist, 'rows', 'stable');
    
    % if iter<=inf
    %   xlist_ = restore_section_thickness(xlist, st, stc, C, com, options);
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
    compute_pflist(@pffun, xlist, com, options, cache);
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

  % --- 終了判定 ---
  if all(vio<=0) && pfval-pfvalold>=omega && all(viold<=0)
    if options.do_progressive_cost_change
      if iter>options.progressive_cost_change_iter+1
        exitflag = PRM.EXITFLAG_CONVERGED;
        break
      end
    else
      exitflag = PRM.EXITFLAG_CONVERGED;
      break
    end
  end

  % --- 関数値が改良されないときの処理 ---
  vnorm = sum(vio.^ppp,2)^(1/ppp);
  vnormold = sum(viold.^ppp,2)^(1/ppp);
  if pfval-pfvalold >= omega
    % if (pfval-pfvalold < 1 && ~isupdatedmu) ...
    %     && (vnorm-vnormold>=-0.01 && any(vio>0))
    % if fval-fold>=omega || (vnorm-vnormold>=-0.001 && any(vio>0))
    do_restration = options.do_restration;
    is_aborted = false;
    isupdatedmu = true;

    % SA
    if options.do_SA
      temprature = iter/max_iter;
      prob = 1-temprature;
      rrr = rand;
      %fprintf(' dpf:%f t:%f r:%f p:%f',pfval-pfvalold,temprature,rrr,prob)
      if rrr>prob
        is_aborted = true;
        %fprintf(' Aborted.\n')
      else
        %fprintf(' \n')
      end
    end

    % 更新を破棄
    if is_aborted
      xvar = xold;
      pfval = pffun(fvalold, cvecold);
    end

    %[x0, pfval, id] = find_best_point(history.f, history.violation, muvec);
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
      break
    end

    % ペナルティ係数更新法その１
    muvec = update_muvec(muvec, r, vio, tau);

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
  else
    isupdatedmu = false;
  end

  viold = vio;
  pfvalold = pfval;
  xold = xvar;
  cvecold = cvec;
  fvalold = fval;
end

if isempty(iter)
  iter = start_iter;
end

time = toc;
finalize_history();
[xopt, pfopt, fopt, vopt, id] = find_best_point(...
  history.xvar, history.fval, history.vio);
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
        fprintf(['Iter:%4d pf:%6.2f f:%6.2f (%d/%d->%d) ' ...
          'cmax:%6.3f vnorm:%6.3f mu:%6.1f '], ...
          iter, pfval, fval, nlist0, nlist, idpfval, maxvio, vnorm, max(muvec));
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
    fval = objective_lsr(xvar, secmgr, baseline, node, section, member, story, floor, options);
    return
  end
%--------------------------------------------------------------------------
  function [pfval, vio] = pffun(fval, cvec)
    vio = cvec;
    % ---
    % idc2 = cumsum(ncon);
    % idc1 = [1 idc2(1:nvio-1)+1];
    % vio = zeros(nvio,1);
    % for i=1:nvio
    %   vio(i) = max(cvec(idc1(i):idc2(i)));
    % end
    vio(vio<tau) = 0;
    switch penalty_method
      case PRM.PENALTY_SUM_TOTAL
        pfval = fval+sum(vio(:).*muvec(:));
      case PRM.PENALTY_MAXIMUM
        % pfval = fval+sum(muvec)*max(vio);
        vvv = sum(vio.^ppp,2)^(1/ppp);
        pfval = fval+max(muvec)*vvv;
    end
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
    history.xvar = zeros(max_iter,mx);
    history.fval = zeros(max_iter,1);
    history.cvec = zeros(max_iter,nc);
    history.pf = zeros(max_iter,1);
    history.muvec = zeros(max_iter,nc);
    history.vio = zeros(max_iter,nvio);
    history.nexec = zeros(max_iter,1);
    history.time = zeros(max_iter,1);
    history.iter = zeros(max_iter,1);
  end
%--------------------------------------------------------------------------
  function save_history
    history.xvar(iter,:) = xvar;
    history.fval(iter) = fval;
    history.cvec(iter,:) = cvec;
    history.vio(iter,:) = vio;
    history.pf(iter) = pfval;
    history.mu(iter,:) = muvec;
    history.nexec(iter) = nexec;
    history.time(iter) = time;
    history.iter(iter) = iter;
  end
%--------------------------------------------------------------------------
  function finalize_history
    history.xvar = history.xvar(1:iter,:);
    history.fval = history.fval(1:iter);
    history.cvec = history.cvec(1:iter,:);
    history.vio = history.vio(1:iter,:);
    history.pf = history.pf(1:iter);
    history.muvec = history.mu(1:iter,:);
    history.nexec = history.nexec(1:iter);
    history.time = history.time(1:iter);
    history.iter = history.iter(1:iter);
  end
%--------------------------------------------------------------------------
end
