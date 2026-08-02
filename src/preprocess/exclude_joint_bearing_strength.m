function isjbs = exclude_joint_bearing_strength(com)
%exclude_joint_bearing_strength - 保有耐力接合（仕口）の除外指定
%   名目梁単位で判定。戻り値は [nng×2]。
%   WFS梁端が剛接合かつHSS柱に接合する場合のみ対象。
%   断面算定省略（F）指定の梁は対象外。

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

% HSS柱の節点集合
col = com.member.column;
ctype = com.member.property.section_type(col.idme);
hss = (ctype == PRM.HSS);
cnode = sort([col.idnode1(hss); col.idnode2(hss)]);

% 判定: WFS梁 かつ 剛接合 かつ HSS柱に接合
isjbs = false(nng, 2);
is_wfs = (ng_stype == PRM.WFS);
isjbs(is_wfs, 1) = (ng_joint1(is_wfs) == PRM.FIX);
isjbs(is_wfs, 2) = (ng_joint2(is_wfs) == PRM.FIX);

% HSS柱に接合しない端部は除外
isjbs(:,1) = isjbs(:,1) & ismember(ng_node1, cnode);
isjbs(:,2) = isjbs(:,2) & ismember(ng_node2, cnode);

% 断面算定省略（F）指定の梁は対象外
isjbs(~nominal_girder.is_allowable_stress, :) = false;

return
end
