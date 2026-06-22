function depth_projection = ...
  calc_girder_vertical_depth_projection(depth, cxl)
%calc_girder_vertical_depth_projection - 梁せいを鉛直方向へ投影
%
%   depth_projection = calc_girder_vertical_depth_projection(depth, cxl)
%   は、梁せい depth を梁軸方向余弦 cxl に基づいて鉛直方向へ
%   投影した値を返す。水平梁では入力 depth と同じ値を返す。
%
%   入力引数:
%     depth - 梁せい [n×1]
%     cxl   - 梁軸方向余弦 [n×3]
%
%   出力引数:
%     depth_projection - 鉛直投影後の梁せい [n×1]


depth_projection = depth;
horizontal_norm = sqrt(cxl(:, 1).^2 + cxl(:, 2).^2);
mask = depth ~= 0 & horizontal_norm > PRM.TOL_DIR;
depth_projection(mask) = depth(mask) ./ horizontal_norm(mask);

return
end
