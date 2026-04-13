function lm_brace_cost = calc_brace_cost_length(...
  member_brace, member_girder, member_column, ...
  node, stype_sec, idsecc2sec, idsecg2sec, secdim)
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

% 梁せいの取得（上層の梁せいで内法を決定）
Hg = zeros(size(secdim,1), 1);
Hg(stype_sec==PRM.WFS) = secdim(stype_sec==PRM.WFS, 1);
Hg(stype_sec==PRM.RCRS) = secdim(stype_sec==PRM.RCRS, 2);
idmg2s = idsecg2sec(member_girder.idsecg);
Hg_gir = Hg(idmg2s);

% 柱幅の取得（断面種別ごと）
Dc = zeros(size(secdim, 1), 1);
Dc(stype_sec == PRM.HSS) = secdim(stype_sec == PRM.HSS, 1);
Dc(stype_sec == PRM.RCRS) = secdim(stype_sec == PRM.RCRS, 3);
idmc2s = idsecc2sec(member_column.idsecc);
Dc_col = Dc(idmc2s);

% 梁レベル調整
glv = member_girder.level;

% 接続梁・柱・ブレース節点
brc_idmeg1 = member_brace.idmeg1;
brc_idmeg2 = member_brace.idmeg2;
brc_idmec1 = member_brace.idmec1;
brc_idmec2 = member_brace.idmec2;
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

% 初期化
nmeb = length(member_brace.idme);
lm_brace_cost = zeros(nmeb, 1);

for ib = 1:nmeb
  in1 = idnode1(ib);
  in2 = idnode2(ib);

  % 接続梁
  idg1 = brc_idmeg1(ib,:);
  idg1 = idg1(idg1 > 0);
  idg2 = brc_idmeg2(ib,:);
  idg2 = idg2(idg2 > 0);

  % z_standard + glv
  [z1, ig1] = endpoint_z(node.z_standard(in1), idg1, glv);
  [z2, ig2] = endpoint_z(node.z_standard(in2), idg2, glv);

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
  ist_lo = min(node.idstory(in1), node.idstory(in2));
  ist_hi = max(node.idstory(in1), node.idstory(in2));
  D1 = col_depth_in_range(brc_idmec1(ib,:), ...
    Dc_col, member_column, ist_lo, ist_hi);
  D2 = col_depth_in_range(brc_idmec2(ib,:), ...
    Dc_col, member_column, ist_lo, ist_hi);
  Lx_inner = Lx - D1 / 2 - D2 / 2;

  % --- 積算長さ ---
  lm_brace_cost(ib) = sqrt(Lz_inner^2 + Lx_inner^2);
end

return
end

function D = col_depth_in_range(idc_raw, ...
  Dc_col, member_column, ist_lo, ist_hi)
%col_depth_in_range - フロア範囲内の柱幅を返す
%
%   D = col_depth_in_range(idc_raw, Dc_col,
%     member_column, ist_lo, ist_hi) は、
%   柱IDリスト中でブレースのフロア範囲内にある
%   柱の幅を返す。該当なしは0。
%
%   入力引数:
%     idc_raw       - 柱部材ID（0含む）
%     Dc_col        - 柱幅配列
%     member_column - 柱部材テーブル
%     ist_lo        - ブレース下端ストーリID
%     ist_hi        - ブレース上端ストーリID
%
%   出力引数:
%     D - 柱幅

D = 0;
idc = idc_raw(idc_raw > 0);
for ic = idc
  idf = member_column.idfloor(ic);
  if idf >= ist_lo && idf <= ist_hi
    D = Dc_col(ic);
    return
  end
end

return
end

