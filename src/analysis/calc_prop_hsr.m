function section_property = calc_prop_hsr(secdim)
%calc_prop_hsr - 円形鋼管の断面性能を計算する
%
%   section_property = calc_prop_hsr(secdim) は、円形鋼管の外径と板厚
%   から断面性能を計算する（計算編付録1.3）。せん断力検討用断面積Aw
%   は全断面積の1/2とし、せん断形状係数κは局所y軸・z軸まわりとも1
%   とする。
%
%   入力引数:
%     secdim - 断面寸法 [n×2以上]（列1: 外径D、列2: 板厚t [mm]）
%
%   出力引数:
%     section_property - 断面性能 [n×14]
%       [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, kappay,
%        kappaz]。Zyfは円形鋼管に該当しないため0

% 計算の準備
D = secdim(:,1);  % 外径
t = secdim(:,2);  % 板厚
n = length(D);

% (1) 全断面積 A
% A = π·t·(D-t)  式(1.29)
A = pi .* t .* (D - t);

% (2) 断面2次モーメント I
% I = (π/64){D^4 - (D-2t)^4}  式(1.30)
I = (pi/64) .* (D.^4 - (D - 2*t).^4);

% x方向とy方向は同じ値
Iy = I;
Iz = I;

% (3) 断面係数 Z
% Z = I/(D/2)  式(1.31)
Z = I ./ (D/2);
Zy = Z;
Zz = Z;

% (4) せん断力検討用断面積 Aw
% Aw = π·t·(D-t)/2  式(1.32)
Aw = pi .* t .* (D - t) / 2;

% せん断有効断面積（x方向、z方向とも同じ）
Asy = Aw;
Asz = Aw;

% (5) 塑性断面係数 Zp
% Zp = (1/6){D^3 - (D-2t)^3}  式(1.33)
Zp = (1/6) .* (D.^3 - (D - 2*t).^3);
Zpy = Zp;
Zpz = Zp;

% ねじり定数 J（円形鋼管の場合、極断面2次モーメントの2倍）
% J = 2·I = (π/32){D^4 - (D-2t)^4}
JJ = 2 * I;

% フランジの断面係数（円形鋼管には該当しないため0）
Zyf = zeros(n, 1);

% せん断形状係数（局所y軸・z軸まわりとも1）
kappay = ones(n, 1);
kappaz = kappay;

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, ...
  kappay, kappaz];

return
end
