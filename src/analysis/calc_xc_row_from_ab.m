function xc_row = calc_xc_row_from_ab(xa, xb, lnom, lb1, lb2, xc_center)
%calc_xc_row_from_ab - xa,xbから重なり判定しxc行を返す
if abs(xc_center - xa) < 1e-6
  xa_L = max(xa - lb1, 0);
  xc_row = [xa_L, xa, xb];
elseif abs(xc_center - xb) < 1e-6
  xb_R = min(xb + lb2, lnom);
  xc_row = [xa, xb, xb_R];
else
  xc_row = [xa, xb, nan];
end

return
end
