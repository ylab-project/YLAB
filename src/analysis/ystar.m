function [cyl, cxl] = ystar(xs, ys, zs, xe, ye, ze, angle)
%ystar - 局所y*軸およびx軸の方向余弦を算出
%
%   [cyl, cxl] = ystar(xs, ys, zs, xe, ye, ze, angle) は、
%   部材の始端・終端座標と材軸回転角から、局所y*軸およびx軸の
%   方向余弦ベクトルを算出する。方向余弦が直接与えられない場合に
%   使用し、y*軸は水平かつLmdaz*zが正または零となる方向とする。
%
%   入力引数:
%     xs    - 始端x座標 [n×1]
%     ys    - 始端y座標 [n×1]
%     zs    - 始端z座標 [n×1]
%     xe    - 終端x座標 [n×1]
%     ye    - 終端y座標 [n×1]
%     ze    - 終端z座標 [n×1]
%     angle - 材軸回転角 [n×1] (rad)
%
%   出力引数:
%     cyl - 局所y*軸の方向余弦 [n×3]
%     cxl - 局所x軸の方向余弦 [n×3]

l = sqrt((xe-xs).^2+(ye-ys).^2+(ze-zs).^2);
cx = (xe-xs)./l;
cy = (ye-ys)./l;
cz = (ze-zs)./l;
cxl = [cx cy cz];

albar = sqrt(cx.^2+cy.^2);
albar_ = max(albar, 1e-6);
c1 = -cy./albar_.*cos(angle)-cz.*cx./albar_.*sin(angle);
c2 = cx./albar_.*cos(angle)-cy.*cz./albar_.*sin(angle);
c3 = albar.*sin(angle);
cyl = [c1 c2 c3];
iccc = (albar < 1e-6);
ccc = [-sin(angle) cos(angle) zeros(length(angle),1)];
cyl(iccc,:) = ccc(iccc,:);
return
end
