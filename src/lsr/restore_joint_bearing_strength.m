function xlist = restore_joint_bearing_strength(xlist0, ...
  member, matF, matGrade, secmgr, options, isjbs, nominal_girder)
%restore_joint_bearing_strength - 仕口の保有耐力接合の復元
%
%   xlist = restore_joint_bearing_strength(xlist0, member, ...
%     matF, matGrade, secmgr, options, isjbs, nominal_girder) は、
%   梁端別の仕口検定に基づき名目梁単位で復元候補を生成する。
%
%   入力引数:
%     xlist0 - 復元前の設計変数候補 [n×nx]
%     member - 柱・梁の部材情報
%     matF, matGrade - 材料の基準強度と鋼種
%     secmgr - 断面管理オブジェクト
%     options - 解析・復元のオプション
%     isjbs - 名目梁の左右端の評価対象 [nng×2]
%     nominal_girder - 名目梁と分割部材の対応
%
%   出力引数:
%     xlist - 復元した設計変数候補 [nres×nx]

[nlist0, nx] = size(xlist0);
xcell = cell(nlist0, 1);

% 名目梁の端部節点を取得
girder = member.girder;
idmeg = nominal_girder.idmeg;
[ng_node1, ng_node2] = get_nominal_girder_end_nodes(girder, idmeg);

if options.jbs_mu_formula == PRM.JBS_AIJ ...
    && any(isjbs & is_tube_column_end(member, ng_node1, ng_node2), 'all')
  % 真値評価と同じく、梁端節点へ柱上端が接続する下側柱を対応付ける
  col = member.column;
  nc_ = length(col.idme);
  nn_ = max([col.idnode1; col.idnode2; girder.idnode1; girder.idnode2]);
  node2col = cell(nn_, 1);
  for ic_ = 1:nc_
    n2_ = col.idnode2(ic_);
    node2col{n2_}(end+1) = ic_;
  end
  if nlist0 == 1 || ~options.do_parallel
    for id = 1:nlist0
      xcell{id} = restore_individual_aij(xlist0(id,:), member, matF, ...
        matGrade, secmgr, options, isjbs, nominal_girder, ng_node1, ...
        ng_node2, node2col);
    end
  else
    parfor id = 1:nlist0
      xcell{id} = restore_individual_aij(xlist0(id,:), member, matF, ...
        matGrade, secmgr, options, isjbs, nominal_girder, ng_node1, ...
        ng_node2, node2col);
    end
  end
else
  if nlist0 == 1 || ~options.do_parallel
    for id = 1:nlist0
      xcell{id} = restore_individual_std(xlist0(id,:), member, matF, ...
        matGrade, secmgr, options, isjbs, nominal_girder, ...
        ng_node1, ng_node2);
    end
  else
    parfor id = 1:nlist0
      xcell{id} = restore_individual_std(xlist0(id,:), member, matF, ...
        matGrade, secmgr, options, isjbs, nominal_girder, ...
        ng_node1, ng_node2);
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
  matF, matGrade, secmgr, options, isjbs, nominal_girder, ...
  ng_node1, ng_node2)
%restore_individual_std - 柱寸法によらない仕口の梁断面を復元する
%
%   xlist = restore_individual_std(xvar, member, matF, matGrade, ...
%     secmgr, options, isjbs, nominal_girder, ng_node1, ng_node2) は、
%   基準解説書で検定する梁に対して断面リストから充足候補を探す。
%
%   入力引数:
%     xvar - 復元前の設計変数 [1×nx]
%     member - 部材情報
%     matF, matGrade - 材料の基準強度と鋼種
%     secmgr - 断面管理オブジェクト
%     options - 解析・復元のオプション
%     isjbs - 左右端の評価対象 [nng×2]
%     nominal_girder - 名目梁と分割部材の対応
%     ng_node1, ng_node2 - 名目梁の左右端節点 [nng×1]
%
%   出力引数:
%     xlist - 復元後の設計変数 [1×nx]、不要なら空

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

% 部材の諸元
Zpy = sprop.Zpy(idm2s);

% 材料定数
F = secmgr.extractMemberMaterialF(secdim, matF);
grade_mem = secmgr.extractMemberMaterialGrade(secdim, matGrade);

% 名目梁の代表部材から断面諸量を取得
idm_ng = girder.idme(idmeg(:, 1));
Zpyg_ng = Zpy(idm_ng);
Fg_ng = F(idm_ng);
grade_ng = grade_mem(idm_ng);
sdimg_ng = msdim(idm_ng, :);

% 仕口の保有耐力接合制約の計算（名目梁単位、isjbs対象に圧縮）
sigu_col = calc_sigu_col(member, F(member.column.idme), ...
  ng_node1, ng_node2);
is_tube = is_tube_column_end(member, ng_node1, ng_node2);
[conjbs, ~, idjbs] = calc_joint_bearing_strength(sdimg_ng, ...
  Zpyg_ng, Fg_ng, grade_ng, sigu_col, [], is_tube, isjbs, options);
if all(conjbs <= 0)
  return
end

% 復元操作が必要な名目梁のチェック（idjbsで全梁indexに復元）
ing_target = idjbs(conjbs > 0);
isec_targets = unique(idm2s(idm_ng(ing_target)));
nstarget = length(isec_targets);

% 復元操作
secdim_res = secdim;
for i = 1:nstarget
  % 該当断面
  isg = isec_targets(i);
  sdim_ = secdim(isg, 1:4);

  % リストの断面性能計算（第7列は候補断面表の行番号）
  idslist_ = secdim(isg, PRM.MAPPED_SECDIM_SLIST);
  [sdimlist, idsection_] = secmgr.getDimension(idslist_);
  n = size(sdimlist, 1);
  sdimlist = [sdimlist(:,1:5) idslist_*ones(n,1) idsection_];
  sproplist = calc_secprop(sdimlist, PRM.WFS, scallop);
  Zpylist = sproplist.Zpy;

  % 該当名目梁ごとの許容性確認
  ing_sec = ing_target(idm2s(idm_ng(ing_target)) == isg);
  isok = false(n, length(ing_sec));
  for j = 1:length(ing_sec)
    ig = ing_sec(j);
    Fi = Fg_ng(ig) * ones(n, 1);
    grade_i = grade_ng(ig) * ones(n, 1);
    sc_i = repmat(sigu_col(ig, :), n, 1);
    conjbs_ = calc_joint_bearing_strength(sdimlist, Zpylist, ...
      Fi, grade_i, sc_i, [], repmat(is_tube(ig, :), n, 1), ...
      repmat(isjbs(ig, :), n, 1), options);
    isok(:, j) = conjbs_ < 0;
  end
  isok = all(isok, 2);
  sdimlist_ = sdimlist(isok, :);
  if isempty(sdimlist_)
    continue
  end
  [~, idcand] = min(pdist2(sdim_, sdimlist_(:, 1:4)));
  sdim_res = sdimlist_(idcand, :);

  % 代表断面に変換
  idsrep = idsec2srep(isg);
  idsec = idsrep2sec(idsrep);
  secdim_res(idsec, :) = sdim_res;
end
xlist = secmgr.findNearestXvar(secdim_res, options);

return

end

%----------------------------------------------------------
function xlist = restore_individual_aij(xvar, member, ...
  matF, matGrade, secmgr, options, isjbs, nominal_girder, ...
  ng_node1, ng_node2, node2col)
%restore_individual_aij - 接合部設計指針の柱・梁候補を復元する
%
%   xlist = restore_individual_aij(xvar, member, matF, matGrade, ...
%     secmgr, options, isjbs, nominal_girder, ...
%     ng_node1, ng_node2, node2col) は、式を梁端別に選択して
%   復元候補を評価する。柱候補の更新は指針を使う端に限る。
%
%   入力引数:
%     xvar - 復元前の設計変数 [1×nx]
%     member - 部材情報
%     matF, matGrade - 材料の基準強度と鋼種
%     secmgr - 断面管理オブジェクト
%     options - 解析・復元のオプション
%     isjbs - 左右端の評価対象 [nng×2]
%     nominal_girder - 名目梁と分割部材の対応
%     ng_node1, ng_node2 - 名目梁の左右端節点 [nng×1]
%     node2col - 節点に柱頭が接続する柱番号のセル配列
%
%   出力引数:
%     xlist - 復元した設計変数候補 [nres×nx]

col = member.column;
girder = member.girder;
idm2s = secmgr.idme2sec;
idmeg = nominal_girder.idmeg;
nc = length(col.idme);
scallop = options.girder_scallop_size;
idsec2var_ = secmgr.idsec2var;
xlist = [];

% 断面計算
stype = secmgr.idsec2stype;
secdim = secmgr.findNearestSection(xvar, options);
msdim = secdim(idm2s, 1:4);
sprop = calc_secprop(secdim, stype, scallop, secmgr);
Zpy = sprop.Zpy(idm2s);
F = secmgr.extractMemberMaterialF(secdim, matF);
grade_mem = secmgr.extractMemberMaterialGrade(secdim, matGrade);

% 名目梁の代表部材から断面諸量を取得
idm_ng = girder.idme(idmeg(:, 1));
Zpyg_ng = Zpy(idm_ng);
Fg_ng = F(idm_ng);
grade_ng = grade_mem(idm_ng);

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

% JBS制約計算（名目梁単位、isjbs対象に圧縮）
sdimg_ng = msdim(idm_ng, :);
sigu_col = calc_sigu_col(member, Fcol_, ng_node1, ng_node2);
is_tube = is_tube_column_end(member, ng_node1, ng_node2);
[conjbs, ~, idjbs] = calc_joint_bearing_strength(sdimg_ng, ...
  Zpyg_ng, Fg_ng, grade_ng, sigu_col, m_num_col, is_tube, isjbs, ...
  options);
if all(conjbs <= 0)
  return
end

% NG名目梁ごとに候補生成 + 集約候補
nx = length(xvar);
n_target = length(idjbs);
xlist = zeros(n_target*5+1, nx);
nlist = 0;
xvar_agg = xvar;
for it = 1:n_target
  if conjbs(it) <= 0
    continue
  end
  ing = idjbs(it);
  ime = idm_ng(ing);
  isec_beam = idm2s(ime);
  sdim_beam_cur = secdim(isec_beam, 1:4);
  idslist_beam = secdim(isec_beam, PRM.MAPPED_SECDIM_SLIST);
  Fg_i = Fg_ng(ing);

  % 各端の支配HSS柱を特定（名目梁の端部節点）
  nodes_end = [ng_node1(ing), ng_node2(ing)];
  ic_end = zeros(1, 2);
  isec_col_end = zeros(1, 2);
  sdim_col_cur_end = zeros(2, 2);
  idslist_col_end = zeros(1, 2);
  Fcol_end = zeros(1, 2);
  for iend = 1:2
    if ~isjbs(ing, iend) || ~is_tube(ing, iend)
      continue
    end
    ic_list = node2col{nodes_end(iend)};
    if isempty(ic_list), continue, end
    [~, imin] = min(m_num_each(ic_list));
    ic = ic_list(imin);
    ic_end(iend) = ic;
    isec_col = idm2s(col.idme(ic));
    isec_col_end(iend) = isec_col;
    sdim_col_cur_end(iend, :) = secdim(isec_col, 1:2);
    idslist_col_end(iend) = secdim(isec_col, PRM.MAPPED_SECDIM_SLIST);
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
  is_beam_cand = ismember(sdimlist_H(:, 2), B_nb);
  beam_sdim_cands = sdimlist_H(is_beam_cand, :);
  beam_cands = beam_sdim_cands(:, 1:4);
  % calc_prop_wfs出力列: 1=A, 9=Zpy（table生成を避けて直接参照）
  beam_props = calc_prop_wfs(beam_sdim_cands, scallop);
  beam_area_cands = beam_props(:, 1);
  beam_zpy_cands = beam_props(:, 9);

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
  col_area_cands = cell(1, 2);
  for iend = 1:2
    if ic_end(iend) == 0
      col_cands{iend} = sdim_col_cur_end(iend, :);
      if col_cands{iend}(1) == 0
        col_cands{iend} = [1, 0];
      end
      col_area_cands{iend} = 0;
      continue
    end
    if m_cur(iend) >= 1 - eps
      col_cands{iend} = sdim_col_cur_end(iend, :);
      col_area_cands{iend} = sprop.A(isec_col_end(iend));
      continue
    end
    sdimlist_col = secmgr.getDimension(idslist_col_end(iend));
    D_vals = unique(sdimlist_col(:, 1));
    idx_D = find(D_vals == sdim_col_cur_end(iend, 1), 1);
    if isempty(idx_D), idx_D = 1; end
    D_nb = D_vals(idx_D:min(end, idx_D+1));
    is_col_cand = ismember(sdimlist_col(:, 1), D_nb);
    col_cands{iend} = sdimlist_col(is_col_cand, 1:2);
    col_props = calc_prop_hss(sdimlist_col(is_col_cand, :));
    col_area_cands{iend} = col_props(:, 1);  % 1列目=A
  end

  nb  = size(beam_cands, 1);
  nc1 = size(col_cands{1}, 1);
  nc2 = size(col_cands{2}, 1);
  n = nb * nc1 * nc2;

  % 全組合せに展開
  br = repmat(repmat(beam_cands, nc1, 1), nc2, 1);
  c1r = repmat(repelem(col_cands{1}, nb, 1), nc2, 1);
  c2r = repelem(col_cands{2}, nb*nc1, 1);
  beam_area = repmat(repmat(beam_area_cands, nc1, 1), nc2, 1);
  col1_area = repmat(repelem(col_area_cands{1}, nb, 1), nc2, 1);
  col2_area = repelem(col_area_cands{2}, nb*nc1, 1);
  area_sum = beam_area + col1_area + col2_area;
  Zpy_cand = repmat(repmat(beam_zpy_cands, nc1, 1), nc2, 1);

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

  % 柱形状に応じた式を対象端だけに適用する
  Fg_cand = Fg_i .* ones(n, 1);
  grade_cand = grade_ng(ing) .* ones(n, 1);
  conjbs_cand = calc_joint_bearing_strength(br, Zpy_cand, Fg_cand, ...
    grade_cand, repmat(sigu_col(ing, :), n, 1), m_num_cand, ...
    repmat(is_tube(ing, :), n, 1), repmat(isjbs(ing, :), n, 1), options);

  % 距離（主寸法 + 付随寸法）
  dist_all = sum(abs(br(:,2:4) - sdim_beam_cur(2:4)), 2) ...
    + sum(abs(c1r - sdim_col_cur_end(1,:)), 2) ...
    + sum(abs(c2r - sdim_col_cur_end(2,:)), 2);

  % 充足候補は断面積和、非充足候補は制約違反を優先
  is_ok = conjbs_cand < 0;
  rank_value = conjbs_cand;
  rank_value(is_ok) = area_sum(is_ok);
  [~, ord] = sortrows([double(~is_ok), rank_value, dist_all]);

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

% 集約候補で xlist を構成
% ON のときだけ共通ヘルパーに委譲し集約候補 1 行に置換する。
% OFF のときは個別候補のみ返す（仕様 cgsr_aggregation_spec.md §4.0）。
xlist = xlist(1:nlist, :);
if options.do_aggregated_restore
  xlist = select_aggregated_or_individual(xlist, xvar, xvar_agg);
end

return
end
