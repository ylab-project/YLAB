function [fval, fdetail, cost] = objective_lsr(xvar, ...
  secmgr, ~, node, section, member, story, floor, options)
%objective_lsr - 断面最適化の目的関数（鉄骨コスト）
%
%   [fval, fdetail, cost] = objective_lsr(xvar,
%   secmgr, ~, node, section, member, story,
%   floor, options) は、
%   設計変数 xvar に対応する断面寸法から部材重量・
%   コストを算出し、目的関数値を返す。
%
%   入力引数:
%     xvar    - 設計変数ベクトル
%     secmgr  - SectionManager オブジェクト
%     node    - 節点データ構造体
%     section - 断面データ構造体
%     member  - 部材データ構造体
%     story   - 層データ構造体
%     floor   - 床データ構造体
%     options - 計算オプション構造体
%
%   出力引数:
%     fval    - 総コスト [スカラ]
%     fdetail - 部位別の重量・コスト詳細 [構造体]
%     cost    - 積算用データ [構造体]

% 共通配列
stype = secmgr.idsec2stype;
mtype = member.property.type;
idm2stype = secmgr.idme2stype;
idm2s = secmgr.idme2sec;
idmg2m = member.girder.idme;
idmc2m = member.column.idme;
idsc2s = section.column.idsec;
idsg2s = section.girder.idsec;
idscb2s = idsc2s(section.column_base.idsecc);

cbstiff = section.column_base.property;
column_base = section.column_base;
column_base_list = secmgr.column_base_list;

% 断面積の計算
secdim = secmgr.findNearestSection(xvar, options);
sprop = calc_secprop(secdim, stype, [], secmgr);
A = sprop.A;
Am = A(idm2s);

% RC断面を除外
Am(idm2stype == PRM.RCRS) = 0;

if nargin == 4
  options.do_autoupdate_floor_height = false;
  options.consider_allowable_stress_at_face = false;
end

% 基礎柱寸法
Dcb = secdim(idscb2s, 1);
cbs = calc_column_base_section(Dcb, cbstiff, column_base, ...
  column_base_list);

% 基礎柱面寸法（統一断面ID→Df）
Df_foundation = zeros(size(secdim, 1), 1);
for icb = 1:length(column_base.idsecc)
  if cbs.Df(icb) > 0
    ids_ = idsc2s(column_base.idsecc(icb));
    Df_foundation(ids_) = cbs.Df(icb);
  end
end

% 柱: 標準階高ベースの積算長さ
mcol_ = member.column;
mgir_ = member.girder;
lm_col = calc_column_weight_length(mcol_, mgir_, floor, ...
  node, stype, idsc2s, idsg2s, secdim);

% 梁: 柱面間内法の積算長さ
lm_gir = calc_girder_weight_length(mgir_, node, stype, ...
  idsg2s, secdim, Df_foundation);

% ブレース: 標準階高の内法対角長
mbrc_ = member.brace;
lm_brc = calc_brace_cost_length(mbrc_, mgir_, mcol_, ...
  node, story, floor, stype, idsc2s, idsg2s, secdim);

% 水平ブレース等は節点座標から直接計算
idm2n = [member.property.idnode1 member.property.idnode2];
dx = node.x(idm2n(:,2)) - node.x(idm2n(:,1));
dy = node.y(idm2n(:,2)) - node.y(idm2n(:,1));
dz = node.z(idm2n(:,2)) - node.z(idm2n(:,1));
lm = sqrt(dx.^2 + dy.^2 + dz.^2);

% lm_cost 組み立て
lm_cost = lm;
lm_cost(mtype == PRM.COLUMN) = lm_col;
lm_cost(mtype == PRM.GIRDER) = lm_gir;
lm_cost(mtype == PRM.BRACE) = lm_brc;

% コスト係数・コスト定数
ids2slist = SectionManager.getSectionListMapping(secdim);
cfm = secmgr.getMemberCostFactor(ids2slist, options);
ccm = secmgr.getMemberCostConstant(ids2slist);

% 部材重量（ton）
wm = Am .* lm_cost * 1e-3 * PRM.RHOS * 1e-6;

% 総コスト（円）= Σ(コスト係数 × 重量 + コスト定数)
fval = sum(cfm .* wm + ccm);

if nargout >= 2
  nsublist = secmgr.getNumSectionSubList;
  fdetail.weight = sum(wm);
  fdetail.weight_girder = sum(wm(idmg2m));
  fdetail.weight_column = sum(wm(idmc2m));
  fdetail.weight_sublist = zeros(nsublist, 1);
  fdetail.cost = fval;
  fdetail.cost_girder = sum(cfm(idmg2m) .* wm(idmg2m) + ccm(idmg2m));
  fdetail.cost_column = sum(cfm(idmc2m) .* wm(idmc2m) + ccm(idmc2m));
  fdetail.cost_sublist = zeros(nsublist, 1);
  % リスト別集計
  idm2sslist = secmgr.getIdMemberToSubList(ids2slist);
  fdetail.weight_sublist = zeros(secmgr.nlist, 1);
  fdetail.cost_sublist = zeros(secmgr.nlist, 1);
  for id = 1:nsublist
    istarget = (idm2sslist == id);
    fdetail.weight_sublist(id) = sum(wm(istarget));
    fdetail.cost_sublist(id) = sum( ...
      cfm(istarget) .* wm(istarget) + ccm(istarget));
  end
end

if nargout >= 3
  % 積算用データの構築
  idsb2s = section.brace.idsec;
  idshb2s = section.horizontal_brace.idsec;

  % 水平ブレース積算用部材長
  lm_hbr = calc_hbrace_cost_length(member.horizontal_brace, node);

  % 各部位の積算データ
  [w_, ~, s_, m_] = calc_steel_cost_column(mcol_, stype, ...
    idsc2s, secdim, lm_cost, Am, secmgr);
  cost.column.weight = w_;
  cost.column.idsec = s_;
  cost.column.idmat = m_;
  [w_, ~, s_, m_] = calc_steel_cost_girder(mgir_, stype, ...
    idsg2s, secdim, lm_cost, Am, secmgr);
  cost.girder.weight = w_;
  cost.girder.idsec = s_;
  cost.girder.idmat = m_;
  [w_, ~, s_, m_] = calc_steel_cost_brace(mbrc_, idsb2s, ...
    secdim, lm_cost, Am, secmgr);
  cost.brace.weight = w_;
  cost.brace.idsec = s_;
  cost.brace.idmat = m_;
  cost.brace.lm = lm_brc;
  mhbr_ = member.horizontal_brace;
  [w_, ~, s_, m_] = calc_steel_cost_hbrace(mhbr_, idshb2s, ...
    secdim, lm_hbr, Am, secmgr);
  cost.hbrace.weight = w_;
  cost.hbrace.idsec = s_;
  cost.hbrace.idmat = m_;
  cost.hbrace.lm = lm_hbr;
end

return
end
