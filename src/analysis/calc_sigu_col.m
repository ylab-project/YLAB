function sigu_col = calc_sigu_col(member, Fcol, ng_node1, ng_node2)
%calc_sigu_col - 梁端の柱σuを算定
%   SS7式6.62のσu = min(柱σu, 梁σu)の柱側σu成分を
%   梁端ごとに算定する。戻り値は [nng × 2]。

col = member.column;
girder = member.girder;

% 柱F値→σu変換（BCR295はσu=400）
suc = zeros(size(Fcol));
suc(Fcol==235 | Fcol==295) = 400;
suc(Fcol==325) = 490;

% 節点→柱σu最小値のマッピング
nn = max([col.idnode1; col.idnode2; girder.idnode1; girder.idnode2]);
sucn = inf(nn, 1);
nc = length(col.idme);
for ic = 1:nc
  n1 = col.idnode1(ic);
  n2 = col.idnode2(ic);
  sucn(n1) = min(sucn(n1), suc(ic));
  sucn(n2) = min(sucn(n2), suc(ic));
end

% 名目梁端の柱σu [nng × 2]
sigu_col = [sucn(ng_node1), sucn(ng_node2)];

return
end
