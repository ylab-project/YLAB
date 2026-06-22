function [isxdir, isydir] = classify_girder_xy_direction(dx, dy)
%classify_girder_xy_direction - 梁端点差から梁のX/Y方向を分類
%
%   [isxdir, isydir] = classify_girder_xy_direction(dx, dy) は、
%   節点同一化後の梁端点差から、梁の平面内X/Y方向フラグを返す。
%
%   入力引数:
%     dx, dy - 梁端点のX/Y座標差 [nmg×1]
%
%   出力引数:
%     isxdir - X方向に寄与する梁
%     isydir - Y方向に寄与する梁

adx = abs(dx);
ady = abs(dy);
is_xy = abs(adx - ady) <= PRM.TOL_DIR ...
  & (adx > PRM.TOL_DIR | ady > PRM.TOL_DIR);
isxdir = adx > ady + PRM.TOL_DIR | is_xy;
isydir = ady > adx + PRM.TOL_DIR | is_xy;

return
end
