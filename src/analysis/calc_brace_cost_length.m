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

% 水平距離
Lx_all = calc_brace_Lx(member_brace, node);

% 梁せい（断面種別ごと、梁ごと）
idmg2s = idsecg2sec(member_girder.idsecg);
Hg_gir = calc_girder_section_depth(secdim, stype_sec(idmg2s), idmg2s);

% 柱幅（断面種別ごと、柱ごと）
Dc = zeros(size(secdim, 1), 1);
Dc(stype_sec == PRM.HSS) = secdim(stype_sec == PRM.HSS, 1);
Dc(stype_sec == PRM.RCRS) = secdim(stype_sec == PRM.RCRS, 3);
idmc2s = idsecc2sec(member_column.idsecc);
Dc_col = Dc(idmc2s);

% 梁レベル調整
glv = member_girder.level;

% ブレース両端の採用梁・接続柱・節点
selected_girder1 = member_brace.idmeg_selected1;
selected_girder2 = member_brace.idmeg_selected2;
brc_idmec1 = member_brace.idmec1;
brc_idmec2 = member_brace.idmec2;
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
  Lx = Lx_all(ib);
  % 端点側へ伸びる柱を接続形態・階番号に依存せず選ぶ。下端(in1)は
  % 上昇柱(idnode1==in1)、上端(in2)は下降柱(idnode2==in2)を採用し、
  % 多層ブレースで上下端の階が離れても各端点の柱幅を正しく減算する。
  D1 = col_depth_at_brace_end(brc_idmec1(ib,:), Dc_col, ...
    member_column, in1, true);
  D2 = col_depth_at_brace_end(brc_idmec2(ib,:), Dc_col, ...
    member_column, in2, false);
  Lx_inner = Lx - D1 / 2 - D2 / 2;

  % --- 積算長さ ---
  lm_brace_cost(ib) = sqrt(Lz_inner^2 + Lx_inner^2);
end

return
end

function D = col_depth_at_brace_end(idc_raw, Dc_col, ...
  member_column, innode, is_ascend)
%col_depth_at_brace_end - ブレース端点に接続する柱の幅を返す
%
%   D = col_depth_at_brace_end(idc_raw, Dc_col,
%     member_column, innode, is_ascend) は、ブレース端点
%   innode からブレース本体側へ伸びる柱の幅を返す。
%   is_ascend が真なら innode を下端(idnode1)とする上昇柱、
%   偽なら innode を上端(idnode2)とする下降柱を選ぶ。
%   接続形態・階番号に依存せず節点接続のみで判定するため、
%   多層ブレースやダミー層でも端点側の柱を正しく選べる。
%   該当なしは0。
%
%   入力引数:
%     idc_raw       - 柱部材ID（0含む）
%     Dc_col        - 柱幅配列
%     member_column - 柱部材テーブル
%     innode        - ブレース端点の節点番号
%     is_ascend     - true:上昇柱(下端) / false:下降柱(上端)
%
%   出力引数:
%     D - 柱幅

D = 0;
idc = idc_raw(idc_raw > 0);
for ic = idc
  if is_ascend
    is_match = member_column.idnode1(ic) == innode;
  else
    is_match = member_column.idnode2(ic) == innode;
  end
  if is_match
    D = Dc_col(ic);
    return
  end
end

return
end
