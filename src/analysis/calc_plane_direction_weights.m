function [wgx, wgy] = calc_plane_direction_weights(cxl)
%calc_plane_direction_weights - 方向余弦から水平面内のX/Y重みを計算

ch2 = cxl(:,1).^2 + cxl(:,2).^2;
ch2(ch2==0) = 1;
wgx = cxl(:,1).^2 ./ ch2;
wgy = cxl(:,2).^2 ./ ch2;

return
end
