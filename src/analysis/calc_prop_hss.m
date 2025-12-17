function section_property = calc_prop_hss(secdim)
%CALC_PROP_HSS この関数の概要をここに記述
%   詳細説明をここに記述

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

% ダミー
Zyf = zeros(n,1);
% Aw = zeros(n,1);
% Aw = A;
Aw = Asy;

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw];
end

