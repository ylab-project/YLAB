function section_property = calc_prop_wfs(secdim, scallop)
%CALC_PROP_WFS この関数の概要をここに記述
%   詳細説明をここに記述

if nargin<2 || isempty(scallop)
  scallop = 0;
end

% 計算の準備
H = secdim(:,1);
B = secdim(:,2);
tw = secdim(:,3);
tf = secdim(:,4);
r = secdim(:,5);

% 断面性能の計算
rd = (1-2/3/(4-pi))*r;
rA = (1-pi/4)*r.^2;
rI = (1/3-pi/16-1/9/(4-pi))*r.^4;
A = H.*B-(B-tw).*(H-2*tf)+4*rA;
Asy = (H-2*tf).*tw;
Asz = B.*tf.*2;
Aw = (H-2*tf-2*scallop).*tw;
% Ai = A-2*scallop*tw;
Af = B.*tf*2;
If1 = B.*tf.^3/12 + B.*tf.*(H-tf).^2/4;
Iw1 = tw.*(H-2*tf).^3/12;
Ir1 = rI+rA.*((H-2*tf)/2-rd).^2;
Iy = 2*If1 + Iw1 + 4*Ir1;
If2 = tf.*B.^3/12;
Iw2 = (H-2*tf).*tw.^3/12;
Ir2 = rI+rA.*(tw/2+rd).^2;
Iz = 2*If2 + Iw2 + 4*Ir2;
Zy = Iy./(H/2);
Zz = Iz./(B/2);
Zyf = B.*(H.^3-(H-2*tf).^3)./(6*H);
Zpy = B.*tf.*(H-tf) + 1/4*tw.*(H-2*tf).^2 + 2*rA.*(H-2*tf-2*rd);
Zpz = 1/2*B.^2.*tf + 1/4*(H-2*tf).*tw.^2 + 2*rA.*(tw+2*rd);
JJ = ((B.*tf.^3)*2 + ((H-2*tf).*tw.^3))/3;

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, Af];
end

