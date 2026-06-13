function [joint_top, joint_bottom] = calc_column_joint_length( ...
  member_column, member_girder, node, stype_sec, idsecg2sec, secdim)
%calc_column_joint_length - 柱仕口部長さを算出
%
%   [joint_top, joint_bottom] =
%     calc_column_joint_length(member_column,
%     member_girder, node, stype_sec,
%     idsecg2sec, secdim) は、
%   SS7マニュアル 4.4.1 に基づき柱頭・柱脚の
%   仕口部長さを算出する。
%
%   仕口部の長さは、ノードに接続する４方向の梁の最上部から
%   最下部までの鉛直距離を、柱軸方向へ投影した長さとする。
%   斜行梁は梁せいを鉛直方向へ投影してから計算する。
%
%   入力引数:
%     member_column - 柱部材構造体
%     member_girder - 梁部材構造体
%     node          - 節点構造体
%     stype_sec     - 断面種別配列 [nsec x 1]
%     idsecg2sec    - 梁断面→統一断面ID変換配列
%     secdim        - 断面寸法配列 [nsec x ncol]
%
%   出力引数:
%     joint_top    - 柱頭の仕口部長さ [nmec x 1] (mm)
%     joint_bottom - 柱脚の仕口部長さ [nmec x 1] (mm)

nmec = length(member_column.idme);

% 梁せい取得（S梁のみ: 鉄骨積算の仕口部はS梁で決まる）
Hs = zeros(size(secdim, 1), 1);
Hs(stype_sec == PRM.WFS) = secdim(stype_sec == PRM.WFS, 1);
idmg2s = idsecg2sec(member_girder.idsecg);
Hg = Hs(idmg2s);

% 梁の鉛直投影せい（斜行梁の補正）
Hg_proj = calc_projected_depth(Hg, member_girder, node);

% 柱軸方向への投影係数（斜め柱の補正）
col_proj = column_axial_projection(member_column.cz_std);

% 梁レベル調整
glv = member_girder.level;

% 柱に接続する梁ID [nmec x 2]
idgx1 = member_column.idmeg_face1x;
idgy1 = member_column.idmeg_face1y;
idgx2 = member_column.idmeg_face2x;
idgy2 = member_column.idmeg_face2y;

% BRACE2→BRACE1対応マップ
ctype = member_column.type;
is_brace2 = ctype == PRM.COLUMN_FOR_BRACE_BODY;
is_brace1 = ctype == PRM.COLUMN_FOR_BRACE_FOUNDATION;
brace1_pair = zeros(nmec, 1);
for ic = 1:nmec
  if ~is_brace2(ic)
    continue
  end
  nom_id = member_column.idnominal(ic, 1);
  ic_b1 = find(member_column.idnominal(:, 1) == nom_id & is_brace1, 1);
  if ~isempty(ic_b1)
    brace1_pair(ic) = ic_b1;
  end
end

joint_top = zeros(nmec, 1);
joint_bottom = zeros(nmec, 1);

for ic = 1:nmec
  % BRACE1（基礎梁内RC部分）はスキップ
  if ctype(ic) == PRM.COLUMN_FOR_BRACE_FOUNDATION
    continue
  end

  % --- 柱頭: face2 の梁 ---
  idg = [idgx2(ic,:) idgy2(ic,:)];
  idg = idg(idg > 0);
  if ~isempty(idg)
    joint_top(ic) = joint_length(idg) * col_proj(ic);
  end

  % --- 柱脚: face1 の梁 ---
  % BRACE2はBRACE1のface1を使用
  if is_brace2(ic) && brace1_pair(ic) > 0
    ic_f1 = brace1_pair(ic);
  else
    ic_f1 = ic;
  end
  idg = [idgx1(ic_f1,:) idgy1(ic_f1,:)];
  idg = idg(idg > 0);
  if ~isempty(idg)
    joint_bottom(ic) = joint_length(idg) * col_proj(ic);
  end
end

return

  function jlen = joint_length(idg_)
  %joint_length - 梁群の最上部〜最下部の鉛直距離
    top_ = glv(idg_);
    bot_ = glv(idg_) - Hg_proj(idg_);
    jlen = max(top_) - min(bot_);
  end
end

function Hg_proj = calc_projected_depth(Hg, member_girder, node)
%calc_projected_depth - 斜行梁の鉛直投影せい
%
%   Hg_proj = calc_projected_depth(Hg,
%     member_girder, node) は、梁の傾斜角に応じて
%   梁せいを鉛直方向に投影した値を返す。
%   水平梁では Hg_proj = Hg となる。

nmeg = length(Hg);
Hg_proj = Hg;

in1 = member_girder.idnode1;
in2 = member_girder.idnode2;

for ig = 1:nmeg
  if Hg(ig) == 0
    continue
  end
  dx = node.x(in2(ig)) - node.x(in1(ig));
  dy = node.y(in2(ig)) - node.y(in1(ig));
  dz = node.z(in2(ig)) - node.z(in1(ig));
  Lh = sqrt(dx^2 + dy^2);
  if Lh > 0 && dz ~= 0
    Ltotal = sqrt(Lh^2 + dz^2);
    Hg_proj(ig) = Hg(ig) * Ltotal / Lh;
  end
end

return
end
