function m_num_col = calc_col_dim_jbs(member, secdim_col, ...
  Fcol, ng_node1, ng_node2)
%calc_col_dim_jbs - mファクター分子を梁端ごとに算定
%   鋼構造接合部設計指針式6.67のmファクター分子
%   4*t_cf*sqrt(b_j*σ_cy) を柱ごとに計算し、梁端（節点）
%   ごとに最小値を格納する（calc_sigu_col と同パターン）。
%   HSS柱のみ対象。CHS柱は対象外（Inf として扱い m=1）。
%   戻り値は [nng × 2]。

col = member.column;
girder = member.girder;
nc = length(col.idme);

% m_num(ic) = 4*t*sqrt((D-2t)*Fcol)  [HSS柱のみ。その他は Inf]
m_num = inf(nc, 1);
is_hss = member.property.section_type(col.idme) == PRM.HSS;
D = secdim_col(is_hss, 1);
t = secdim_col(is_hss, 2);
m_num(is_hss) = 4 .* t .* sqrt((D - 2.*t) .* Fcol(is_hss));

% 節点→m_num マッピング（柱上端のみ：梁は下の柱に取り付く）
nn = max([col.idnode1; col.idnode2; girder.idnode1; girder.idnode2]);
m_num_node = inf(nn, 1);
for ic = 1:nc
  n2 = col.idnode2(ic);
  m_num_node(n2) = min(m_num_node(n2), m_num(ic));
end

% 名目梁端の m_num [nng × 2]
m_num_col = [m_num_node(ng_node1), m_num_node(ng_node2)];

return
end
