function sigu_col = calc_sigu_col(member, Fcol)
%calc_sigu_col - WFS梁端の柱σuを算定
%   SS7式6.62のσu = min(柱σu, 梁σu)の柱側σu成分を
%   梁端ごとに算定する。戻り値は [nwfs × 2]。

col = member.column;
girder = member.girder;

% 柱F値→σu変換（BCR295はσu=400）
suc = zeros(size(Fcol));
suc(Fcol==235 | Fcol==295) = 400;
suc(Fcol==325) = 490;

% 節点→柱σu最小値のマッピング
nn = max([col.idnode1; col.idnode2; ...
  girder.idnode1; girder.idnode2]);
sucn = inf(nn, 1);
nc = length(col.idme);
for ic = 1:nc
  n1 = col.idnode1(ic);
  n2 = col.idnode2(ic);
  sucn(n1) = min(sucn(n1), suc(ic));
  sucn(n2) = min(sucn(n2), suc(ic));
end

% WFS梁端の柱σu [nwfs × 2]
gt = girder.section_type;
wn1 = girder.idnode1(gt==PRM.WFS);
wn2 = girder.idnode2(gt==PRM.WFS);
sigu_col = [sucn(wn1), sucn(wn2)];

return
end
