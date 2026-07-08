function [lm_girder_weight, face_deduct] = calc_girder_weight_length( ...
  member_girder, node, cxl, stype_sec, idsecg2sec, secdim, ...
  Df_foundation, coord_shift)
%calc_girder_weight_length - 梁荷重計算用の部材長を算出
%
% SS7マニュアル「4.1.1 梁」に基づき、梁の自重・仕上重量計算用の
% 部材長を算出する。
%
% SS7の定義:
%   大梁・片持梁: 柱面間の内法長さ
%   小梁: 通り心間距離
%
% 斜め梁・節点上下移動の場合:
%   数量用の標準系座標 node.z_standard と標準系方向余弦 cxl を使う。
%
% 柱と梁の構造種別による場合分け:
%   同種別（RC-RC, S-S）: 柱面まで
%   S柱（基礎柱あり）-RC梁: 基礎柱面まで
%   S柱（基礎柱なし）-RC梁: 通り心まで
%
% 通し梁（一本部材）の場合:
%   一本部材の両端以外（中間節点）は通り心までとする（柱面減算なし）
%
% 通り心まで端の基準点:
%   「通り心まで」となる梁端（一本部材の中間端、柱面控除がゼロに
%   なる異種構造の組合せ）は、寄り反映後の構造心節点ではなく
%   通り心を基準とする。通り心と構造心のズレは coord_shift で
%   受け取り、梁軸方向に投影して柱面控除量へ加算する。
%   柱面まで端は構造心基準を維持する（柱寄りが通りごとに一様な
%   場合は柱心に一致する。柱ごとに寄りが異なる一般ケースは未対応）。
%
% Inputs:
%   member_girder - 梁部材構造体
%     （idme, idsecg, idsec_facel/r, isthrough, idnode1/2）
%   node          - 節点構造体（x, y, z_standard, idx, idy）
%   cxl           - 標準系の梁軸方向余弦 [nmeg×3]
%   stype_sec     - 断面種別配列 [nsec×1]
%   idsecg2sec    - 梁断面ID→統一断面IDの変換配列
%   secdim        - 断面寸法配列 [nsec×ncol]
%   Df_foundation - 基礎柱面寸法配列 [nsec×1]（統一断面ID→Df）
%   coord_shift   - 構造心と通り心のズレ（任意。
%                   .x [nblx×1], .y [nbly×1]）
%
% Outputs:
%   lm_girder_weight - 梁荷重計算用の部材長配列 [nmeg x 1]
%   face_deduct      - 柱面減算量 [nmeg x 2]（列1: i端, 列2: j端。
%                      通り心まで端の基準点補正を含み、節点の外側へ
%                      延びる場合は負値）

% 梁数
nmeg = length(member_girder.idme);

% S造判定用: HSS/WFSはS造、RCRSはRC造
is_steel_sec = stype_sec == PRM.HSS | stype_sec == PRM.WFS;

% 梁の構造種別（idsecg→統一断面IDへ変換）
idmg2s = idsecg2sec(member_girder.idsecg);
is_steel_g = is_steel_sec(idmg2s);

% 柱せいの取得（断面種別ごと）
Dc = zeros(size(secdim,1),1);
Dc(stype_sec==PRM.HSS) = secdim(stype_sec==PRM.HSS,1);   % 角形鋼管: 1列目
Dc(stype_sec==PRM.RCRS) = secdim(stype_sec==PRM.RCRS,3); % RC柱: 3列目

% 梁の両端の対面柱断面ID（統一断面ID、柱なしは0）
idsec_facel = member_girder.idsec_facel;
idsec_facer = member_girder.idsec_facer;
isthrough = member_girder.isthrough;  % [nmeg×3]
idnode1 = member_girder.idnode1;
idnode2 = member_girder.idnode2;

% 梁端間の標準系3D距離
dz = abs(node.z_standard(idnode2) - node.z_standard(idnode1));
dx = node.x(idnode2) - node.x(idnode1);
dy = node.y(idnode2) - node.y(idnode1);
horizontal = sqrt(dx.^2 + dy.^2);
lm_girder_weight = sqrt(dz.^2 + horizontal.^2);

% 柱面寸法と通り心まで端判定の初期化
face_dimension = zeros(nmeg, 2);
is_to_grid = false(nmeg, 2);

idsec_face = {idsec_facel, idsec_facer};
for ig = 1:nmeg
  for iend = 1:2
    if isthrough(ig, iend)
      is_to_grid(ig, iend) = true;
      continue
    end
    [face_dimension(ig, iend), is_to_grid(ig, iend)] = ...
      calc_face_dimension(idsec_face{iend}(ig,:), is_steel_g(ig), ...
      is_steel_sec, Dc, Df_foundation);
  end
end
[face_deduct, ~, ~] = calc_girder_face_deduct(face_dimension, cxl);

% 通り心まで端の基準点補正
% 構造心節点から通り心へ戻すズレを梁軸方向に投影し、控除量へ
% 加える（i端は減算、j端は加算）。節点の外側へ延びる場合は負の
% 控除になる。通りに載らない節点はズレ0で補正されない。
if nargin >= 8 && ~isempty(coord_shift)
  node_sx = zeros(size(node.x));
  node_sy = zeros(size(node.y));
  has_x = node.idx > 0;
  has_y = node.idy > 0;
  node_sx(has_x) = coord_shift.x(node.idx(has_x));
  node_sy(has_y) = coord_shift.y(node.idy(has_y));
  idnode_end = {idnode1, idnode2};
  sgn = [-1 1];
  for iend = 1:2
    s_axis = node_sx(idnode_end{iend}).*cxl(:,1) ...
      + node_sy(idnode_end{iend}).*cxl(:,2);
    mask = is_to_grid(:, iend);
    face_deduct(mask, iend) = face_deduct(mask, iend) ...
      + sgn(iend)*s_axis(mask);
  end
end
lm_girder_weight = lm_girder_weight - sum(face_deduct, 2);

return
end

function [face_dimension, is_to_grid] = calc_face_dimension( ...
  ids_row, is_steel_g_, is_steel_sec_, Dc, Df_foundation)
%calc_face_dimension - 片端の柱面寸法と通り心まで判定を算出
%
%   [face_dimension, is_to_grid] = calc_face_dimension(ids_row,
%   is_steel_g_, is_steel_sec_, Dc, Df_foundation) は、
%   梁の片端について数量控除対象の柱面寸法と、部材長を通り心まで
%   とする端かどうかを算出する。
%
%   入力引数:
%     ids_row       - 対面柱断面IDの行 [1×ncol]
%     is_steel_g_   - 梁がS造か (logical)
%     is_steel_sec_ - 断面ごとのS造判定 [nsec×1]
%     Dc            - 柱せい配列 [nsec×1]
%     Df_foundation - 基礎柱面寸法 [nsec×1]
%
%   出力引数:
%     face_dimension - 柱面寸法 (scalar)
%     is_to_grid     - 通り心まで端か (logical)。対面柱があり
%                      柱面控除を行わない組合せで true

face_dimension = 0;
is_to_grid = false;
ids = ids_row(ids_row > 0);
if isempty(ids)
  return
end

% 対面柱があり柱面控除が決まらない端は通り心までとする
is_to_grid = true;
for k = 1:length(ids)
  is_steel_c = is_steel_sec_(ids(k));
  if is_steel_g_ == is_steel_c
    % 同種別（S-S または RC-RC）: 柱面まで減算
    face_dimension = Dc(ids(k));
    is_to_grid = false;
    return;
  elseif ~is_steel_g_ && is_steel_c
    % RC梁-S柱: 基礎柱があれば基礎柱面まで、なければ通り心まで
    Df = Df_foundation(ids(k));
    if Df > 0
      face_dimension = Df;
      is_to_grid = false;
    end
    return;
  end
end

return
end
