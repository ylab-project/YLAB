function section_property = calc_prop_rcrs(secdim)
%calc_prop_rcrs - RC矩形断面の断面性能を計算

% 計算の準備
n = size(secdim,1);
% b = secdim(:,1);
% D = secdim(:,2);
b = secdim(:,3);
D = secdim(:,4);

% 断面性能の計算
A = b.*D;
kappa = 1.2;  % せん断形状係数（矩形断面）
Asy = A / kappa;
Asz = A / kappa;
Iy = b.*D.^3/12;
Iz = b.^3.*D/12;
Zy = Iy./(D/2);
Zz = Iz./(b/2);

% 捩り定数（Saint-Venantの矩形断面近似式、短辺bs・長辺Dl基準）
bs = min(b, D);
Dl = max(b, D);
JJ = bs.^3 .* Dl .* (1/3 ...
  - 0.21 * (bs./Dl) .* (1 - (bs.^4)./(12*Dl.^4)));

% ダミー
Aw  = A;
Zyf = Zy;
Zpy = zeros(n,1);
Zpz = zeros(n,1);

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw];
end

