function section_property = calc_prop_rcrs(secdim)
%calc_prop_rcrs - RC矩形断面の断面性能を計算する
%
%   section_property = calc_prop_rcrs(secdim) は、RC矩形断面の幅と
%   せいから断面性能を計算する。せん断形状係数κは局所y軸・z軸まわり
%   とも1.2とし、剛性用せん断面積は全断面積をκで除した値とする。
%
%   入力引数:
%     secdim - 断面寸法 [n×4以上]（列3: 幅b、列4: せいD [mm]）
%
%   出力引数:
%     section_property - 断面性能 [n×14]
%       [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, kappay,
%        kappaz]。ZyfはZy、AwはAと同値、Zpy・Zpzは0

% 計算の準備
n = size(secdim,1);
b = secdim(:,3);
D = secdim(:,4);

% 断面性能の計算
A = b.*D;
% せん断形状係数（矩形断面は局所y軸・z軸まわりとも1.2）
kappay = 1.2*ones(n,1);
kappaz = kappay;
Asy = A./kappay;
Asz = A./kappaz;
Iy = b.*D.^3/12;
Iz = b.^3.*D/12;
Zy = Iy./(D/2);
Zz = Iz./(b/2);

% 捩り定数（Saint-Venantの矩形断面近似式、短辺bs・長辺Dl基準）
bs = min(b, D);
Dl = max(b, D);
JJ = bs.^3 .* Dl .* (1/3 - 0.21 * (bs./Dl) .* (1 - (bs.^4)./(12*Dl.^4)));

% 鉄骨断面と列を揃えるための値
Aw  = A;
Zyf = Zy;
Zpy = zeros(n,1);
Zpz = zeros(n,1);

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, ...
  kappay, kappaz];

return
end
