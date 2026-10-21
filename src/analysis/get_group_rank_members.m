function idme = get_group_rank_members(com, idme)
%get_group_rank_members - 部材の種別判定に関わる部材番号を得る
%
%   idme = get_group_rank_members(com, idme) は、指定した部材が属する
%   名目柱・名目梁の全区間と、その名目柱の両端・内部節点に取り付く
%   名目梁の全区間を全方向からまとめて返す。名目柱・名目梁に属さない
%   部材（ブレースなど）は除く。
%
%   入力引数:
%     com  - 部材・名目部材・節点の対応
%     idme - 部材番号 [nsel×1]
%
%   出力引数:
%     idme - 判定に関わる部材番号 [nrel×1]（昇順、重複なし）

nominal = com.nominal.property;
mp = com.member.property;
inm = unique(nonzeros(mp.idnominal(idme)));
inm = inm(ismember(nominal.mtype(inm), [PRM.COLUMN PRM.GIRDER]));
idme = nonzeros(nominal.idme(inm, :));

% 名目柱の全区間の節点に取り付く梁を名目梁の全区間へ広げる
inmc = inm(nominal.mtype(inm) == PRM.COLUMN);
idmec = nonzeros(nominal.idme(inmc, :));
is_node = false(numel(com.node.idz), 1);
is_node([mp.idnode1(idmec); mp.idnode2(idmec)]) = true;
idmeg = find(mp.type == PRM.GIRDER & ...
  (is_node(mp.idnode1) | is_node(mp.idnode2)));
inmg = unique(nonzeros(mp.idnominal(idmeg)));
idme = unique([idme; nonzeros(nominal.idme(inmg, :))]);

return
end
