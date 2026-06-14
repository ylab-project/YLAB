function [is_gx, is_gy] = classify_girder_cxl_direction(cxl)
%classify_girder_cxl_direction - 方向余弦から梁のX/Y寄与を分類
%
%   [is_gx, is_gy] = classify_girder_cxl_direction(cxl) は、梁材軸の
%   方向余弦から、計算用のX/Y方向寄与フラグを返す。

[wgx, wgy] = calc_plane_direction_weights(cxl);
[is_gx, is_gy] = classify_girder_plane_direction(wgx, wgy);

return
end
