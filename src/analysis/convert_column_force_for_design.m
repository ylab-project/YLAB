function rs = convert_column_force_for_design(rs0, cxl, ~, idmc2m)
%convert_column_force_for_design - 柱設計用の斜め柱応力へ変換
%
%   rs = convert_column_force_for_design(rs0, cxl, cyl, idmc2m) は、
%   全体系XY方向へ変換済みの柱応力 rs0 のうち、斜め柱の設計連鎖で
%   使う曲げ・せん断成分だけを柱直交断面基底へ変換する。

rs = rs0;
nlc = size(rs, 3);
nmc = length(idmc2m);
tol = 1e-6;

for ic = 1:nmc
  im = idmc2m(ic);
  cx = cxl(im, :);
  h = sqrt(cx(1)^2 + cx(2)^2);
  if h < tol || abs(cx(3)) < tol
    continue
  end

  ax = cx(1);
  ay = cx(2);
  az = cx(3);
  h2 = h^2;
  one_minus_az = 1 - az;
  % 全体系X/Y軸を、鉛直軸から柱軸へ最小回転した断面基底に移す。
  ex = [az + ay^2 / h2 * one_minus_az, ...
    -ax * ay / h2 * one_minus_az, -ax];
  ey = [-ax * ay / h2 * one_minus_az, ...
    az + ax^2 / h2 * one_minus_az, -ay];

  % rs0 の行5/2は全体Y成分、行6/3は負の全体X成分を保持する。
  coef_x_my = ey(2) - ey(3) * ay / az;
  coef_x_mx = ey(1) - ey(3) * ax / az;
  coef_y_my = ex(2) - ex(3) * ay / az;
  coef_y_mx = ex(1) - ex(3) * ax / az;

  r = reshape(rs(im, :, :), 12, nlc);

  qy_i = r(2, :);   qx_i = r(3, :);
  my_i = r(5, :);   mx_i = r(6, :);
  qy_j = r(8, :);   qx_j = r(9, :);
  my_j = r(11, :);  mx_j = r(12, :);

  r(2, :) = coef_x_my * qy_i - coef_x_mx * qx_i;
  r(3, :) = coef_y_mx * qx_i - coef_y_my * qy_i;
  r(5, :) = coef_x_my * my_i - coef_x_mx * mx_i;
  r(6, :) = coef_y_mx * mx_i - coef_y_my * my_i;
  r(8, :) = coef_x_my * qy_j - coef_x_mx * qx_j;
  r(9, :) = coef_y_mx * qx_j - coef_y_my * qy_j;
  r(11, :) = coef_x_my * my_j - coef_x_mx * mx_j;
  r(12, :) = coef_y_mx * mx_j - coef_y_my * my_j;

  rs(im, :, :) = reshape(r, 1, 12, nlc);
end

return
end
