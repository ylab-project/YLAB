function [conhsmoothvar, Dmat, varH] = ...
  calc_girder_height_smooth_var(xvar, height_smooth, options)
%calc_girder_height_smooth_var - 梁せい分布平滑化制約を計算
%   初期化時に生成した固定データから梁せいと差分行列を取得し、
%   梁せい分布の平滑化制約を計算する。

[Dmat, varH] = Hdiff_matrix(xvar, height_smooth, options);
conhsmoothvar = Dmat * varH(:) / 50;
return
end