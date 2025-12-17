function section_property = calc_prop_rcrs(secdim)
%CALC_PROP_HSS この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
n = size(secdim,1);
% b = secdim(:,1);
% D = secdim(:,2);
b = secdim(:,3);
D = secdim(:,4);

% 断面性能の計算
A = b.*D;
Asy = A;
Asz = A;
Iy = b.*D.^3/12;
Iz = b.^3.*D/12;
Zy = Iy./(D/2);
Zz = Iz./(b/2);

% ダミー
JJ = A;
Aw  = A;
Zyf = Zy;
Zpy = zeros(n,1);
Zpz = zeros(n,1);
% JJ = zeros(n,1);
% Zyf = zeros(n,1);

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw];
end

