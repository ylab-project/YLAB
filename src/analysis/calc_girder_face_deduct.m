function [face_deduct_axis, face_deduct_horizontal, axis_factor] = ...
  calc_girder_face_deduct(face_dimension_x, face_dimension_y, cxl)
%calc_girder_face_deduct - 梁端柱面寸法から軸方向控除を算出
%
%   [face_deduct_axis, face_deduct_horizontal, axis_factor] =
%     calc_girder_face_deduct(face_dimension_x, face_dimension_y,
%     cxl) は、梁端ごとの柱のX・Y方向の外形寸法から、水平投影面で
%     柱心から柱面へ到達する距離と梁軸方向の控除長さを算出する。
%     柱の外形は柱心を中心とする矩形とみなし、梁の水平方向で
%     X面・Y面のうち先に到達する面までの距離
%     min(Dx/(2|cx|), Dy/(2|cy|)) を柱面到達距離とする。
%
%   入力引数:
%     face_dimension_x - 梁端柱面のX方向寸法 [nmeg×2]
%                        （列1: i端, 列2: j端）
%     face_dimension_y - 梁端柱面のY方向寸法 [nmeg×2]
%     cxl              - 梁軸方向余弦 [nmeg×3]
%
%   出力引数:
%     face_deduct_axis       - 梁軸方向の柱面控除 [nmeg×2]
%     face_deduct_horizontal - 水平投影面の柱面到達距離 [nmeg×2]
%     axis_factor            - 水平投影長から梁軸長への換算係数 [nmeg×1]

nmeg = size(face_dimension_x, 1);
face_deduct_horizontal = zeros(nmeg, 2);

horizontal_norm = sqrt(cxl(:, 1).^2 + cxl(:, 2).^2);
axis_factor = ones(nmeg, 1);
is_horizontal_axis = horizontal_norm >= PRM.TOL_DIR;
axis_factor(is_horizontal_axis) = 1 ./ horizontal_norm(is_horizontal_axis);

cxh = zeros(nmeg, 1);
cyh = zeros(nmeg, 1);
cxh(is_horizontal_axis) = cxl(is_horizontal_axis, 1) ...
  ./ horizontal_norm(is_horizontal_axis);
cyh(is_horizontal_axis) = cxl(is_horizontal_axis, 2) ...
  ./ horizontal_norm(is_horizontal_axis);

for ig = 1:nmeg
  for iend = 1:2
    Dx = face_dimension_x(ig, iend);
    Dy = face_dimension_y(ig, iend);
    if ~is_horizontal_axis(ig)
      % 水平成分のない部材は方向を定めず、大きい方の半幅とする
      face_deduct_horizontal(ig, iend) = max(Dx, Dy) / 2;
    elseif abs(cyh(ig)) < PRM.TOL_DIR
      % X軸に沿う梁はX面まで
      face_deduct_horizontal(ig, iend) = Dx / 2;
    elseif abs(cxh(ig)) < PRM.TOL_DIR
      % Y軸に沿う梁はY面まで
      face_deduct_horizontal(ig, iend) = Dy / 2;
    else
      % 斜め梁は柱心を中心とする矩形のX面・Y面のうち先に到達する
      % 面まで
      tx = (Dx / 2) / abs(cxh(ig));
      ty = (Dy / 2) / abs(cyh(ig));
      face_deduct_horizontal(ig, iend) = min(tx, ty);
    end
  end
end

% 軸方向控除 = 水平投影控除 × 軸換算係数（列方向は暗黙拡張）
face_deduct_axis = face_deduct_horizontal .* axis_factor;

return
end
