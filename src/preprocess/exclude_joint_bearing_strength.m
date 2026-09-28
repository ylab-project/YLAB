function isjbs = exclude_joint_bearing_strength(com)
%exclude_joint_bearing_strength - 保有耐力接合（仕口）の除外指定
%
%   isjbs = exclude_joint_bearing_strength(com) は名目梁端を判定する。
%   H形鋼梁の剛接合端で角形鋼管柱・H形鋼柱への接続を対象とする。
%   RC柱が接続する梁端と断面算定省略（F）指定の梁は対象外。
%
%   入力引数:
%     com - 共通構造体
%
%   出力引数:
%     isjbs - 名目梁の左右端の評価対象フラグ [nng×2]

girder = com.member.girder;
nominal_girder = com.nominal.girder;
idmeg = nominal_girder.idmeg;
nng = size(idmeg, 1);

% 名目梁の端部節点を取得
[ng_node1, ng_node2] = get_nominal_girder_end_nodes(girder, idmeg);

% 名目梁の端部結合条件（最初の部材のi端、最後の部材のj端）
ng_joint1 = girder.joint(idmeg(:, 1), 1);
ng_joint2 = zeros(nng, 1);
for ing = 1:nng
  ids = nonzeros(idmeg(ing, :));
  ng_joint2(ing) = girder.joint(ids(end), 2);
end

% 名目梁の断面タイプ（代表部材から）
ng_stype = girder.section_type(idmeg(:, 1));

% 検定対象の柱の節点集合
col = com.member.column;
ctype = com.member.property.section_type(col.idme);
istarget = ismember(ctype, [PRM.HSS PRM.CWFS PRM.CWFSI]);
% RC柱との上下境界は保有耐力接合の対象外（SS7 1.22で確認）
is_rc = ctype == PRM.RCRS;
cnode = setdiff([col.idnode1(istarget); col.idnode2(istarget)], ...
  [col.idnode1(is_rc); col.idnode2(is_rc)]);

% 判定: WFS梁 かつ 剛接合 かつ 対象柱に接合
isjbs = false(nng, 2);
is_wfs = (ng_stype == PRM.WFS);
isjbs(is_wfs, 1) = (ng_joint1(is_wfs) == PRM.FIX);
isjbs(is_wfs, 2) = (ng_joint2(is_wfs) == PRM.FIX);

% 対象柱に接合しない端部は除外
isjbs(:,1) = isjbs(:,1) & ismember(ng_node1, cnode);
isjbs(:,2) = isjbs(:,2) & ismember(ng_node2, cnode);

% 断面算定省略（F）指定の梁は対象外
isjbs(~nominal_girder.is_allowable_stress, :) = false;

return
end
