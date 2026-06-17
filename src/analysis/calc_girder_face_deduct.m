function [face_deduct_axis, face_deduct_horizontal, axis_factor] = ...
  calc_girder_face_deduct(face_dimension, cxl)
%calc_girder_face_deduct - 梁端柱面寸法から軸方向控除を算出
%
%   [face_deduct_axis, face_deduct_horizontal, axis_factor] =
%     calc_girder_face_deduct(face_dimension, cxl) は、
%   梁端ごとの柱面寸法から、水平投影面の柱面到達距離と
%   梁軸方向の控除長さを算出する。
%
%   入力引数:
%     face_dimension - 梁端柱面寸法 [nmeg×2]（列1: i端, 列2: j端）
%     cxl            - 梁軸方向余弦 [nmeg×3]
%
%   出力引数:
%     face_deduct_axis       - 梁軸方向の柱面控除 [nmeg×2]
%     face_deduct_horizontal - 水平投影面の柱面到達距離 [nmeg×2]
%     axis_factor            - 水平投影長から梁軸長への換算係数 [nmeg×1]

TOL = 1e-6;

nmeg = size(face_dimension, 1);
face_deduct_horizontal = zeros(nmeg, 2);

horizontal_norm = sqrt(cxl(:, 1).^2 + cxl(:, 2).^2);
axis_factor = ones(nmeg, 1);
is_horizontal_axis = horizontal_norm >= TOL;
axis_factor(is_horizontal_axis) = 1 ./ horizontal_norm(is_horizontal_axis);

cxh = zeros(nmeg, 1);
cyh = zeros(nmeg, 1);
cxh(is_horizontal_axis) = cxl(is_horizontal_axis, 1) ...
  ./ horizontal_norm(is_horizontal_axis);
cyh(is_horizontal_axis) = cxl(is_horizontal_axis, 2) ...
  ./ horizontal_norm(is_horizontal_axis);

for ig = 1:nmeg
  for iend = 1:2
    D = face_dimension(ig, iend);
    if D <= 0
      continue
    end

    if ~is_horizontal_axis(ig) || abs(cxh(ig)) < TOL || abs(cyh(ig)) < TOL
      face_deduct_horizontal(ig, iend) = D / 2;
    else
      tx = (D / 2) / abs(cxh(ig));
      ty = (D / 2) / abs(cyh(ig));
      face_deduct_horizontal(ig, iend) = min(tx, ty);
    end
  end
end

% 軸方向控除 = 水平投影控除 × 軸換算係数（列方向は暗黙拡張）
face_deduct_axis = face_deduct_horizontal .* axis_factor;

return
end
