function [dir_girder, is_gx, is_gy] = ...
  classify_girder_plane_direction(wgx, wgy)
%classify_girder_plane_direction - 梁の平面内実配置方向を分類
%
%   [dir_girder, is_gx, is_gy] =
%     classify_girder_plane_direction(wgx, wgy) は、
%   梁の水平面内 cos2θ 重みから、K計算用の主方向を返す。
%
%   入力引数:
%     wgx, wgy - X/Y方向への cos2θ 重み [nmg×1]
%
%   出力引数:
%     dir_girder - PRM.X/Y/XY による実配置方向 [nmg×1]
%     is_gx      - X方向に寄与する梁
%     is_gy      - Y方向に寄与する梁

tol = 1e-12;
is_xy = abs(wgx - wgy) <= tol & (wgx > tol | wgy > tol);
is_gx = wgx > wgy + tol | is_xy;
is_gy = wgy > wgx + tol | is_xy;

dir_girder = zeros(size(wgx));
dir_girder(is_gx & ~is_gy) = PRM.X;
dir_girder(~is_gx & is_gy) = PRM.Y;
dir_girder(is_gx & is_gy) = PRM.XY;

return
end
