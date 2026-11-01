function lm_brace_cost = calc_brace_cost_length(member_brace, ...
  member_girder, member_column, node, stype_sec, idsecc2sec, ...
  idsecg2sec, secdim)
%calc_brace_cost_length - ブレース積算用部材長を算出
%
%   lm_brace_cost = calc_brace_cost_length(
%     member_brace, member_girder, member_column,
%     node, stype_sec, idsecc2sec, idsecg2sec,
%     secdim) は、
%   SS7積算マニュアル(4.4.5)に基づき、ブレースの
%   積算用部材長を算出する。node.z_standard ベースの
%   内法対角長を返す。
%
%   入力引数:
%     member_brace  - ブレース部材テーブル
%     member_girder - 梁部材テーブル
%     member_column - 柱部材テーブル
%     node          - 節点テーブル (z_standard 必須)
%     stype_sec     - 断面種別 [nsec×1]
%     idsecc2sec    - 柱断面→統一断面ID
%     idsecg2sec    - 梁断面→統一断面ID
%     secdim        - 断面寸法 [nsec×ncol]
%
%   出力引数:
%     lm_brace_cost - 積算用部材長 [nmeb×1]

% 梁せい（断面種別ごと、梁ごと）
idmg2s = idsecg2sec(member_girder.idsecg);
Hg_gir = calc_girder_section_depth(secdim, stype_sec(idmg2s), idmg2s);

% 柱幅（X方向、Y方向）。鉄骨柱は向きを含む外形、RC柱は荷重剛性用
% 寸法（3列目）。両端の柱幅の半分を控除した構面方向の水平距離を得る
idmc2s = idsecc2sec(member_column.idsecc);
Dc_col = calc_column_outer_size(secdim(idmc2s, :), stype_sec(idmc2s), 3);
Lx_inner_all = calc_brace_Lx_inner(member_brace, member_column, ...
  node, Dc_col);

% 梁レベル調整
glv = member_girder.level;

% ブレース両端の採用梁・節点
selected_girder1 = member_brace.idmeg_selected1;
selected_girder2 = member_brace.idmeg_selected2;
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

nmeb = length(member_brace.idme);
lm_brace_cost = zeros(nmeb, 1);

for ib = 1:nmeb
  in1 = idnode1(ib);
  in2 = idnode2(ib);

  ig1 = selected_girder1(ib);
  ig2 = selected_girder2(ib);

  z1 = node.z_standard(in1);
  z2 = node.z_standard(in2);
  if ig1 > 0
    z1 = z1 + glv(ig1);
  end
  if ig2 > 0
    z2 = z2 + glv(ig2);
  end

  % --- 鉛直内法距離（上層の梁せいを減算） ---
  Lz = abs(z2 - z1);
  if z2 >= z1
    if ig2 > 0; H_upper = Hg_gir(ig2); else; H_upper = 0; end
  else
    if ig1 > 0; H_upper = Hg_gir(ig1); else; H_upper = 0; end
  end
  Lz_inner = Lz - H_upper;

  % --- 水平内法距離 ---
  Lx_inner = Lx_inner_all(ib);

  % --- 積算長さ ---
  lm_brace_cost(ib) = sqrt(Lz_inner^2 + Lx_inner^2);
end

return
end
