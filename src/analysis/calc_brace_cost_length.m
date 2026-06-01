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
Hg = zeros(size(secdim,1), 1);
Hg(stype_sec==PRM.WFS) = secdim(stype_sec==PRM.WFS, 1);
Hg(stype_sec==PRM.RCRS) = secdim(stype_sec==PRM.RCRS, 2);
idmg2s = idsecg2sec(member_girder.idsecg);
Hg_gir = Hg(idmg2s);

% 柱幅（断面種別ごと、柱ごと）
Dc = zeros(size(secdim, 1), 1);
Dc(stype_sec == PRM.HSS) = secdim(stype_sec == PRM.HSS, 1);
Dc(stype_sec == PRM.RCRS) = secdim(stype_sec == PRM.RCRS, 3);
idmc2s = idsecc2sec(member_column.idsecc);
Dc_col = Dc(idmc2s);

% 梁レベル調整
glv = member_girder.level;

% ブレース両端の接続梁・柱・節点
brc_idmeg1 = member_brace.idmeg1;
brc_idmeg2 = member_brace.idmeg2;
brc_idmec1 = member_brace.idmec1;
brc_idmec2 = member_brace.idmec2;
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

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
  % ブレース本体の存在階の柱を採用する（接続形態に依存しない統一ルール）
  brace_story = min(node.idstory(in1), node.idstory(in2));
  D1 = col_depth_in_brace_story(brc_idmec1(ib,:), Dc_col, ...
    member_column, brace_story);
  D2 = col_depth_in_brace_story(brc_idmec2(ib,:), Dc_col, ...
    member_column, brace_story);
  Lx_inner = Lx - D1 / 2 - D2 / 2;

  % --- 積算長さ ---
  lm_brace_cost(ib) = sqrt(Lz_inner^2 + Lx_inner^2);
end

return
end

function D = col_depth_in_brace_story(idc_raw, Dc_col, ...
  member_column, brace_story)
%col_depth_in_brace_story - ブレース存在階の柱幅を返す
%
%   D = col_depth_in_brace_story(idc_raw, Dc_col,
%     member_column, brace_story) は、柱IDリスト中で
%   ブレース本体の存在階に伸びる柱の幅を返す。
%   接続形態（K上型・K下型・X形）に依存せず、ガセット
%   プレートが取り付くブレース存在階の柱を選ぶことで
%   SS7と整合する。該当なしは0。
%
%   入力引数:
%     idc_raw       - 柱部材ID（0含む）
%     Dc_col        - 柱幅配列
%     member_column - 柱部材テーブル
%     brace_story   - ブレース存在階のidfloor
%
%   出力引数:
%     D - 柱幅

D = 0;
idc = idc_raw(idc_raw > 0);
for ic = idc
  if member_column.idfloor(ic) == brace_story
    D = Dc_col(ic);
    return
  end
end

return
end

