function section_property = calc_prop_hss(secdim)
%calc_prop_hss - 角形鋼管の断面性能を計算する
%
%   section_property = calc_prop_hss(secdim) は、角形鋼管の外径・板厚・
%   角部の半径から断面性能を計算する（計算編付録1.2）。せん断力検討用
%   断面積Awは全断面積の1/2とし、せん断形状係数κは局所y軸・z軸まわり
%   とも1とする。
%
%   入力引数:
%     secdim - 断面寸法 [n×3以上]（列1: 外径D、列2: 板厚t、列3: 角部の
%              半径r [mm]）
%
%   出力引数:
%     section_property - 断面性能 [n×14]
%       [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, kappay,
%        kappaz]。Zyfは角形鋼管に該当しないため0

% 計算の準備
D = secdim(:,1);
t = secdim(:,2);
r = secdim(:,3);
n = length(D);

% 断面性能の計算
rr = r-t;
dd = D-2*t;
DmR = D/2-r;
dmr = dd/2-rr;
A = (D-2*r).*t*4 + pi.*(r.^2-rr.^2);
Asy = A/2;
Asz = Asy;
Iy = (pi/8*(r.^4-rr.^4) ...
  +4/3*(r.^3.*DmR-rr.^3.*dmr) ...
  +pi/2*(r.^2.*DmR.^2-rr.^2.*dmr.^2) ...
  +2/3*(r.*DmR.^3-rr.*dmr.^3))*2 ...
  +DmR.*(D.^3-dd.^3)/6;
Iz = Iy;
Zy = Iy./(D/2);
Zz = Zy;
Zpy = (D-2*r).*t.*(D-t) ...
  + 1/2*t.*(D-2*r).^2 ...
  + pi*t.*(2*r-t).*(D/2-r+4*(r.^3-(r-t).^3)./((3*pi)*(r.^2-(r-t).^2)));
Zpz = Zpy;
AA = D.^2+pi*r.^2-t.*(2*D+pi*r-4*r) + pi/4*t.^2-4*r.^2;
LL = 4*D-8*r+2*pi*r-pi*t;
JJ = 4*AA.^2.*t./LL;

% フランジのみの断面係数は該当しない
Zyf = zeros(n,1);
Aw = Asy;

% せん断形状係数（局所y軸・z軸まわりとも1）
kappay = ones(n,1);
kappaz = kappay;

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, ...
  kappay, kappaz];

return
end
