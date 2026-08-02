function conhsmoothvar = calc_girder_height_smooth_var(xvar, height_smooth)
%calc_girder_height_smooth_var - 梁せい分布平滑化制約を計算
%
%   conhsmoothvar = ...
%     calc_girder_height_smooth_var(xvar, height_smooth) は、初期化時に
%   作成した同一符号列の差分行列から平滑化制約を計算する。
%
%   入力引数:
%     xvar          - 断面変数
%     height_smooth - 梁せい平滑化の固定データ
%
%   出力引数:
%     conhsmoothvar - 梁せいの層方向差分

varH = xvar(height_smooth.idvarH);
conhsmoothvar = height_smooth.Dmat * varH(:) / 50;

return
end
