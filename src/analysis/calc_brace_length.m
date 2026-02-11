function lm_brace = calc_brace_length(...
  member_brace, member_column, member_girder, ...
  node, stype_sec, idsecc2sec, idsecg2sec, secdim)
%calc_brace_length - SS7 3.8.1準拠のブレース長を算出
%
% ブレース端 = 柱参照線と梁参照線の交点。
% S/SRC/CFT: 構造心（控除なし）。
% RC: コンクリート面（Dc/2, Hg/2控除）。
% 分割節点: glv・Hg/2はnodezに反映済みのためスキップ。
%
% Inputs:
%   member_brace  - ブレース部材構造体
%   member_column - 柱部材構造体
%   member_girder - 梁部材構造体
%   node          - 節点構造体（x, y, z, type）
%   stype_sec     - 断面種別配列 [nsec x 1]
%   idsecc2sec    - 柱断面ID→統一断面ID変換配列
%   idsecg2sec    - 梁断面ID→統一断面ID変換配列
%   secdim        - 断面寸法配列 [nsec x ncol]
%
% Outputs:
%   lm_brace - ブレース長 [nmeb x 1]

nmeb = length(member_brace.idme);

% ブレース節点
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

% 接続する柱・梁の部材番号
brc_idmec1 = member_brace.idmec1;
brc_idmec2 = member_brace.idmec2;
brc_idmeg1 = member_brace.idmeg1;
brc_idmeg2 = member_brace.idmeg2;

% 梁レベル調整（下げが負）
glv = member_girder.level;

% 柱せいの取得（断面種別ごと）
Dc = zeros(size(secdim,1), 1);
Dc(stype_sec==PRM.HSS) = ...
  secdim(stype_sec==PRM.HSS, 1);
Dc(stype_sec==PRM.RCRS) = ...
  secdim(stype_sec==PRM.RCRS, 3);

% 梁せいの取得（断面種別ごと）
Hg = zeros(size(secdim,1), 1);
Hg(stype_sec==PRM.WFS) = ...
  secdim(stype_sec==PRM.WFS, 1);
Hg(stype_sec==PRM.RCRS) = ...
  secdim(stype_sec==PRM.RCRS, 2);

% RC判定
is_rc_sec = stype_sec == PRM.RCRS;

% 柱部材ごとのRC判定・せい
idmc2s = idsecc2sec(member_column.idsecc);
is_rc_col = is_rc_sec(idmc2s);
Dc_col = Dc(idmc2s);

% 梁部材ごとのRC判定・せい
idmg2s = idsecg2sec(member_girder.idsecg);
is_rc_gir = is_rc_sec(idmg2s);
Hg_gir = Hg(idmg2s);

lm_brace = zeros(nmeb, 1);

for ib = 1:nmeb
  in1 = idnode1(ib);
  in2 = idnode2(ib);

  % 分割節点判定（glv・Hg/2スキップ用）
  is_split1 = node.type(in1) ...
    == PRM.NODE_BRACE_FOR_COLUMN;
  is_split2 = node.type(in2) ...
    == PRM.NODE_BRACE_FOR_COLUMN;

  % --- 1. 構造心間距離（成分） ---
  dx = node.x(in2) - node.x(in1);
  dy = node.y(in2) - node.y(in1);
  Lx = sqrt(dx^2 + dy^2);

  % glv補正（分割節点はnodezに反映済み）
  idg1 = brc_idmeg1(ib,:);
  idg1 = idg1(idg1 > 0);
  if is_split1 || isempty(idg1)
    max_glv1 = 0;
  else
    max_glv1 = max(glv(idg1));
  end

  idg2 = brc_idmeg2(ib,:);
  idg2 = idg2(idg2 > 0);
  if is_split2 || isempty(idg2)
    max_glv2 = 0;
  else
    max_glv2 = max(glv(idg2));
  end

  Lz = node.z(in2) - node.z(in1) ...
    + max_glv2 - max_glv1;

  % --- 2. RC面控除（成分ごとに独立） ---
  % 端点1の柱: Dc/2を水平方向から控除
  deduct_x1 = 0;
  idc1 = brc_idmec1(ib,:);
  idc1 = idc1(idc1 > 0);
  for k = 1:length(idc1)
    if is_rc_col(idc1(k))
      deduct_x1 = max(deduct_x1, ...
        Dc_col(idc1(k)) / 2);
    end
  end

  % 端点2の柱
  deduct_x2 = 0;
  idc2 = brc_idmec2(ib,:);
  idc2 = idc2(idc2 > 0);
  for k = 1:length(idc2)
    if is_rc_col(idc2(k))
      deduct_x2 = max(deduct_x2, ...
        Dc_col(idc2(k)) / 2);
    end
  end

  % 端点1の梁: Hg/2を鉛直方向から控除
  % （分割節点はnodezに反映済み）
  deduct_z1 = 0;
  if ~is_split1
    for k = 1:length(idg1)
      if is_rc_gir(idg1(k))
        deduct_z1 = max(deduct_z1, ...
          Hg_gir(idg1(k)) / 2);
      end
    end
  end

  % 端点2の梁
  deduct_z2 = 0;
  if ~is_split2
    for k = 1:length(idg2)
      if is_rc_gir(idg2(k))
        deduct_z2 = max(deduct_z2, ...
          Hg_gir(idg2(k)) / 2);
      end
    end
  end

  Lx_net = Lx - deduct_x1 - deduct_x2;
  Lz_net = abs(Lz) - deduct_z1 - deduct_z2;

  % --- 3. 斜め距離（最終部材長） ---
  lm_brace(ib) = sqrt(Lx_net^2 + Lz_net^2);
end

return
end
