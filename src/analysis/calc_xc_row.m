function xc_row = calc_xc_row(lnom, lb1, lb2, xc_center)
%calc_xc_row - 均等配置のxc絶対座標3列を算出
%
%   左端からlb1間隔、右端からlb2間隔の補剛配置で
%   xc_centerを含む座屈区間を特定する。

% 右区間の開始位置（lb がスパン超過の場合クランプ）
lb1 = min(lb1, lnom);
lb2 = min(lb2, lnom);
x_right = lnom - lb2;

if xc_center >= x_right - 1e-6
  % 中央が右区間に入る場合
  xa = x_right;
  xb = lnom;
else
  % 中央が左側の均等配置区間に入る場合
  nL = floor(xc_center / lb1);
  xa = nL * lb1;
  xb = min(xa + lb1, lnom);
end

xc_row = calc_xc_row_from_ab( ...
  xa, xb, lnom, lb1, lb2, xc_center);

return
end
