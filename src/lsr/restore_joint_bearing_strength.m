function xlist = restore_joint_bearing_strength(xlist0, ...
  member, matF, secmgr, options, isjbs, nominal_girder)
%restore_joint_bearing_strength - 仕口の保有耐力接合の復元
%   名目梁単位で候補を生成する。

[nlist0, nx] = size(xlist0);
xcell = cell(nlist0, 1);

% 名目梁の端部節点を取得
girder = member.girder;
idmeg = nominal_girder.idmeg;
[ng_node1, ng_node2] = ...
  get_nominal_girder_end_nodes(girder, idmeg);

if options.jbs_mu_formula == PRM.JBS_AIJ
  % node2col を事前構築（xvarに依存しないため1回で十分）
  col = member.column;
  nc_ = length(col.idme);
  nn_ = max([col.idnode1; col.idnode2; ...
    girder.idnode1; girder.idnode2]);
  node2col = cell(nn_, 1);
  for ic_ = 1:nc_
    n1_ = col.idnode1(ic_);
    n2_ = col.idnode2(ic_);
    node2col{n1_}(end+1) = ic_;
    node2col{n2_}(end+1) = ic_;
  end
  if nlist0 == 1 || ~options.do_parallel
    for id = 1:nlist0
      xcell{id} = restore_individual_aij( ...
        xlist0(id,:), member, matF, secmgr, ...
        options, isjbs, nominal_girder, ...
        ng_node1, ng_node2, node2col);
    end
  else
    parfor id = 1:nlist0
      xcell{id} = restore_individual_aij( ...
        xlist0(id,:), member, matF, secmgr, ...
        options, isjbs, nominal_girder, ...
        ng_node1, ng_node2, node2col);
    end
  end
else
  secdim0_ = secmgr.findNearestSection( ...
    xlist0(1,:), options);
  F0_ = secmgr.extractMemberMaterialF(secdim0_, matF);
  Fcol_ = F0_(member.column.idme);
  sigu_col = calc_sigu_col(member, Fcol_, ...
    ng_node1, ng_node2);
  if nlist0 == 1 || ~options.do_parallel
    for id = 1:nlist0
      xcell{id} = restore_individual_std( ...
        xlist0(id,:), member, matF, secmgr, ...
        options, sigu_col, nominal_girder);
    end
  else
    parfor id = 1:nlist0
      xcell{id} = restore_individual_std( ...
        xlist0(id,:), member, matF, secmgr, ...
        options, sigu_col, nominal_girder);
    end
  end
end

% 結果の整理
nlist = 0;
xlist = zeros(1000, nx);
for id = 1:nlist0
  ne = size(xcell{id}, 1);
  xlist(nlist+1:nlist+ne,:) = xcell{id};
  nlist = nlist + ne;
end
xlist = xlist(1:nlist,:);
xlist = unique(xlist, 'rows', 'stable');

return
end

%----------------------------------------------------------
function xlist = restore_individual_std(xvar, member, ...
  matF, secmgr, options, sigu_col, nominal_girder)

% 共通配列(ID変換)
girder = member.girder;
idm2s = secmgr.idme2sec;
idmeg = nominal_girder.idmeg;

% 共通配列
stype = secmgr.idsec2stype;
scallop = options.girder_scallop_size;
idsec2srep = secmgr.idsec2srep;
idsrep2sec = secmgr.idsrep2sec;

% 初期化
xlist = [];

% 断面計算
secdim = secmgr.findNearestSection(xvar, options);
msdim = secdim(idm2s, 1:4);
sprop = calc_secprop(secdim, stype, scallop, secmgr);
msprop = sprop(idm2s,:);

% 部材の諸元
Zpy = msprop.Zpy;

% 材料定数
F = secmgr.extractMemberMaterialF(secdim, matF);

% 名目梁の代表部材から断面諸量を取得
idm_ng = girder.idme(idmeg(:, 1));
Zpyg_ng = Zpy(idm_ng);
Fg_ng = F(idm_ng);
sdimg_ng = msdim(idm_ng, :);

% 仕口の保有耐力接合制約の計算（名目梁単位）
conjbs = calc_joint_bearing_strength_std(sdimg_ng, Zpyg_ng, ...
  Fg_ng, sigu_col, [], options);
if all(conjbs <= 0)
  return
end

% 復元操作が必要な名目梁のチェック
ing_target = find(conjbs > 0);
isec_targets = unique(idm2s(idm_ng(ing_target)));
nstarget = length(isec_targets);

% 復元操作
secdim_res = secdim;
for i = 1:nstarget
  % 該当断面
  isg = isec_targets(i);
  sdim_ = secdim(isg, 1:4);

  % リストの断面性能計算
  idslist_ = secdim(isg, 6);
  sdimlist = secmgr.getDimension(idslist_);
  n = size(sdimlist, 1);
  sdimlist = [sdimlist(:,1:5) idslist_*ones(n,1) (1:n)'];
  sproplist = calc_secprop(sdimlist, PRM.WFS, scallop);
  Zpylist = sproplist.Zpy;

  % 該当名目梁ごとの許容性確認
  ing_sec = ing_target(idm2s(idm_ng(ing_target)) == isg);
  isok = false(n, length(ing_sec));
  for j = 1:length(ing_sec)
    ig = ing_sec(j);
    Fi = Fg_ng(ig) * ones(n, 1);
    sc_i = repmat(sigu_col(ig, :), n, 1);
    conjbs_ = calc_joint_bearing_strength_std(sdimlist, ...
      Zpylist, Fi, sc_i, [], options);
    isok(:, j) = conjbs_ < 0;
  end
  isok = all(isok, 2);
  sdimlist_ = sdimlist(isok, :);
  if isempty(sdimlist_)
    continue
  end
  sdim_res = find_feasible_section(sdim_, sdimlist_);

  % 代表断面に変換
  idsrep = idsec2srep(isg);
  idsec = idsrep2sec(idsrep);
  secdim_res(idsec, :) = sdim_res;
end
xlist = secmgr.findNearestXvar(secdim_res, options);

return

  function sdimcand_ = find_feasible_section(sdim_, sdimlist_)
    ddd = pdist2(sdim_, sdimlist_(:, 1:4));
    [~, idcand] = min(ddd);
    sdimcand_ = sdimlist_(idcand, :);
  end
end

%----------------------------------------------------------
function xlist = restore_individual_aij(xvar, member, ...
  matF, secmgr, options, isjbs, nominal_girder, ...
  ng_node1, ng_node2, node2col)

col = member.column;
girder = member.girder;
idm2s = secmgr.idme2sec;
idmeg = nominal_girder.idmeg;
nng = size(idmeg, 1);
nc = length(col.idme);
scallop = options.girder_scallop_size;
idsec2var_ = secmgr.idsec2var;
xlist = [];

% 断面計算
stype = secmgr.idsec2stype;
secdim = secmgr.findNearestSection(xvar, options);
msdim = secdim(idm2s, 1:4);
sprop = calc_secprop(secdim, stype, scallop, secmgr);
msprop = sprop(idm2s, :);
Zpy = msprop.Zpy;
F = secmgr.extractMemberMaterialF(secdim, matF);

% 名目梁の代表部材から断面諸量を取得
idm_ng = girder.idme(idmeg(:, 1));
Zpyg_ng = Zpy(idm_ng);
Fg_ng = F(idm_ng);

% 柱断面・F値
secdim_col = secdim(idm2s(col.idme), :);
Fcol_ = F(col.idme);

% per-column m_num（支配柱の特定用）
m_num_each = inf(nc, 1);
is_hss = member.property.section_type(col.idme) == PRM.HSS;
if any(is_hss)
  D_c = secdim_col(is_hss, 1);
  t_c = secdim_col(is_hss, 2);
  m_num_each(is_hss) = 4.*t_c .* sqrt((D_c - 2.*t_c) .* Fcol_(is_hss));
end

% m_num_col（node集約 [nng×2]）
m_num_col = calc_col_dim_jbs(member, secdim_col, Fcol_, ...
  ng_node1, ng_node2);

% JBS制約計算（名目梁単位）
sdimg_ng = msdim(idm_ng, :);
conjbs = calc_joint_bearing_strength_aij(sdimg_ng, Zpyg_ng, ...
  Fg_ng, m_num_col, isjbs, options);
if all(conjbs <= 0)
  return
end

% NG名目梁ごとに候補生成 + 集約候補
nx = length(xvar);
xlist = zeros(nng*5+1, nx);
nlist = 0;
xvar_agg = xvar;
for ing = 1:nng
  if conjbs(ing) <= 0
    continue
  end
  ime = idm_ng(ing);
  isec_beam = idm2s(ime);
  sdim_beam_cur = secdim(isec_beam, 1:4);
  idslist_beam = secdim(isec_beam, 6);
  Fg_i = Fg_ng(ing);

  % 各端の支配HSS柱を特定（名目梁の端部節点）
  nodes_end = [ng_node1(ing), ng_node2(ing)];
  ic_end = zeros(1, 2);
  isec_col_end = zeros(1, 2);
  sdim_col_cur_end = zeros(2, 2);
  idslist_col_end = zeros(1, 2);
  Fcol_end = zeros(1, 2);
  for iend = 1:2
    ic_list = node2col{nodes_end(iend)};
    if isempty(ic_list), continue, end
    [~, imin] = min(m_num_each(ic_list));
    ic = ic_list(imin);
    if member.property.section_type(col.idme(ic)) ~= PRM.HSS
      continue
    end
    ic_end(iend) = ic;
    isec_col_end(iend) = idm2s(col.idme(ic));
    sdim_col_cur_end(iend, :) = secdim(isec_col_end(iend), 1:2);
    idslist_col_end(iend) = secdim(isec_col_end(iend), 6);
    Fcol_end(iend) = Fcol_(ic);
  end

  % 梁候補：H固定、B∈{B_cur, B+1}
  sdimlist_beam = secmgr.getDimension(idslist_beam);
  mask_H = sdimlist_beam(:,1) == sdim_beam_cur(1);
  sdimlist_H = sdimlist_beam(mask_H, :);
  if isempty(sdimlist_H)
    sdimlist_H = sdimlist_beam(sdimlist_beam(:,1) <= sdim_beam_cur(1), :);
  end
  if isempty(sdimlist_H), continue, end
  B_vals = unique(sdimlist_H(:, 2));
  idx_B = find(B_vals == sdim_beam_cur(2), 1);
  if isempty(idx_B), idx_B = 1; end
  B_nb = B_vals(idx_B:min(end, idx_B+1));
  beam_cands = sdimlist_H(ismember(sdimlist_H(:, 2), B_nb), 1:4);

  % 現在のm（柱候補スキップ判定用）
  denom_cur = (sdim_beam_cur(1) - 2*sdim_beam_cur(4)) ...
    * sqrt(sdim_beam_cur(3) * Fg_i);
  m_cur = zeros(1, 2);
  for iend = 1:2
    if ic_end(iend) == 0
      m_cur(iend) = 1;
    else
      m_cur(iend) = min(1, m_num_col(ing, iend) / denom_cur);
    end
  end

  % 柱候補（各端）：m>=1なら現断面固定
  col_cands = cell(1, 2);
  for iend = 1:2
    if ic_end(iend) == 0
      col_cands{iend} = sdim_col_cur_end(iend, :);
      if col_cands{iend}(1) == 0
        col_cands{iend} = [1, 0];
      end
      continue
    end
    if m_cur(iend) >= 1 - eps
      col_cands{iend} = sdim_col_cur_end(iend, :);
      continue
    end
    sdimlist_col = secmgr.getDimension(idslist_col_end(iend));
    D_vals = unique(sdimlist_col(:, 1));
    idx_D = find(D_vals == sdim_col_cur_end(iend, 1), 1);
    if isempty(idx_D), idx_D = 1; end
    D_nb = D_vals(idx_D:min(end, idx_D+1));
    col_cands{iend} = sdimlist_col(ismember(sdimlist_col(:,1), D_nb), 1:2);
  end

  nb  = size(beam_cands, 1);
  nc1 = size(col_cands{1}, 1);
  nc2 = size(col_cands{2}, 1);
  n = nb * nc1 * nc2;

  % 全組合せに展開
  br = repmat(repmat(beam_cands, nc1, 1), nc2, 1);
  c1r = repmat(repelem(col_cands{1}, nb, 1), nc2, 1);
  c2r = repelem(col_cands{2}, nb*nc1, 1);

  H = br(:,1); B = br(:,2);
  tw = br(:,3); tf = br(:,4);

  % 候補梁の Zpy（候補ごとに再計算）
  Zpy_cand = B.*tf.*(H-tf) + 0.25.*tw.*(H-2.*tf).^2;

  % 候補柱の m_num [n×2]
  m_num_cand = zeros(n, 2);
  if ic_end(1) > 0
    m_num_cand(:,1) = 4.*c1r(:,2) .* sqrt((c1r(:,1) ...
      - 2.*c1r(:,2)) .* Fcol_end(1));
  else
    m_num_cand(:,1) = inf;
  end
  if ic_end(2) > 0
    m_num_cand(:,2) = 4.*c2r(:,2) .* sqrt((c2r(:,1) ...
      - 2.*c2r(:,2)) .* Fcol_end(2));
  else
    m_num_cand(:,2) = inf;
  end

  % calc_joint_bearing_strength_aij で一括評価
  Fg_cand = Fg_i .* ones(n, 1);
  [conjbs_cand, ~] = calc_joint_bearing_strength_aij( ...
    br, Zpy_cand, Fg_cand, m_num_cand, [], options);

  % 距離（主寸法 + 付随寸法）
  dist_all = sum(abs(br(:,2:4) - sdim_beam_cur(2:4)), 2) ...
    + sum(abs(c1r - sdim_col_cur_end(1,:)), 2) ...
    + sum(abs(c2r - sdim_col_cur_end(2,:)), 2);

  % 並べ替え：充足優先→conjbs昇順→距離昇順
  is_ok = conjbs_cand < 0;
  [~, ord] = sortrows([double(~is_ok), conjbs_cand, dist_all]);

  % 上位5件をxvarに書き出し
  n_top = min(n, 5);
  idvars_beam = idsec2var_(isec_beam, :);
  best_idx = ord(1);
  for i = 1:n_top
    idx = ord(i);
    xvar_new = xvar;
    if idvars_beam(2) > 0
      xvar_new(idvars_beam(2)) = br(idx, 2);
    end
    if idvars_beam(3) > 0
      xvar_new(idvars_beam(3)) = br(idx, 3);
    end
    if idvars_beam(4) > 0
      xvar_new(idvars_beam(4)) = br(idx, 4);
    end
    if ic_end(1) > 0 && isec_col_end(1) > 0
      idv = idsec2var_(isec_col_end(1), :);
      if idv(1) > 0
        xvar_new(idv(1)) = c1r(idx, 1);
      end
      if idv(2) > 0
        xvar_new(idv(2)) = c1r(idx, 2);
      end
    end
    if ic_end(2) > 0 && isec_col_end(2) > 0
      idv = idsec2var_(isec_col_end(2), :);
      if idv(1) > 0
        xvar_new(idv(1)) = c2r(idx, 1);
      end
      if idv(2) > 0
        xvar_new(idv(2)) = c2r(idx, 2);
      end
    end
    nlist = nlist + 1;
    xlist(nlist, :) = xvar_new;
  end

  % 集約候補: 梁B,tw,tfはmax、柱D,tはmax
  idx = best_idx;
  if idvars_beam(2) > 0
    xvar_agg(idvars_beam(2)) = max(xvar_agg(idvars_beam(2)), br(idx, 2));
  end
  if idvars_beam(3) > 0
    xvar_agg(idvars_beam(3)) = max(xvar_agg(idvars_beam(3)), br(idx, 3));
  end
  if idvars_beam(4) > 0
    xvar_agg(idvars_beam(4)) = max(xvar_agg(idvars_beam(4)), br(idx, 4));
  end
  if ic_end(1) > 0 && isec_col_end(1) > 0
    idv = idsec2var_(isec_col_end(1), :);
    if idv(1) > 0
      xvar_agg(idv(1)) = max(xvar_agg(idv(1)), c1r(idx, 1));
    end
    if idv(2) > 0
      xvar_agg(idv(2)) = max(xvar_agg(idv(2)), c1r(idx, 2));
    end
  end
  if ic_end(2) > 0 && isec_col_end(2) > 0
    idv = idsec2var_(isec_col_end(2), :);
    if idv(1) > 0
      xvar_agg(idv(1)) = max(xvar_agg(idv(1)), c2r(idx, 1));
    end
    if idv(2) > 0
      xvar_agg(idv(2)) = max(xvar_agg(idv(2)), c2r(idx, 2));
    end
  end
end

% 集約候補を先頭に挿入
if any(xvar_agg(:)' ~= xvar(:)')
  xlist = [xvar_agg(:)'; xlist(1:nlist, :)];
else
  xlist = xlist(1:nlist, :);
end

return
end
