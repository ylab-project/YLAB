function section_property = calc_prop_wfs(secdim, scallop)
%calc_prop_wfs - H形鋼（溶接組立H形鋼含む）の断面性能を計算
%
% 入力:
%   secdim  - 断面寸法 [H, B, tw, tf, r] (mm)
%   scallop - スカラップ寸法 (mm), 省略時は0
%
% 出力:
%   section_property - 断面性能配列
%     [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, Af, Zys]
%
% 断面係数の使い分け:
%   Zy  - スカラップなし断面係数（梁中央部用）
%   Zys - スカラップ考慮断面係数（梁端部用、scallop=0ならZyと同値）
%   Zyf - フランジのみ断面係数（ウェブ非考慮時用）

if nargin<2 || isempty(scallop)
  scallop = 0;
end

% 断面寸法の取得
H = secdim(:,1);   % せい
B = secdim(:,2);   % 幅
tw = secdim(:,3);  % ウェブ厚
tf = secdim(:,4);  % フランジ厚
r = secdim(:,5);   % フィレット半径

% フィレット部の断面性能（正方形−おうぎ形）
rd = (1-2/3/(4-pi))*r;      % 図心位置
rA = (1-pi/4)*r.^2;         % 断面積
rI = (1/3-pi/16-1/9/(4-pi))*r.^4;  % 断面二次モーメント

% 断面積
A = H.*B-(B-tw).*(H-2*tf)+4*rA;  % 全断面積
Asy = (H-2*tf).*tw;              % せん断断面積（y方向）
Asz = B.*tf.*2;                  % せん断断面積（z方向）
Aw = (H-2*tf-2*scallop).*tw;     % ウェブ断面積（スカラップ考慮）
Af = B.*tf*2;                    % フランジ断面積

% 強軸（y軸）まわりの断面二次モーメント
If1 = B.*tf.^3/12 + B.*tf.*(H-tf).^2/4;  % フランジ
Iw1 = tw.*(H-2*tf).^3/12;                 % ウェブ
Ir1 = rI+rA.*((H-2*tf)/2-rd).^2;          % フィレット
Iy = 2*If1 + Iw1 + 4*Ir1;

% 弱軸（z軸）まわりの断面二次モーメント
If2 = tf.*B.^3/12;                        % フランジ
Iw2 = (H-2*tf).*tw.^3/12;                 % ウェブ
Ir2 = rI+rA.*(tw/2+rd).^2;                % フィレット
Iz = 2*If2 + Iw2 + 4*Ir2;

% 断面係数（欠損なし）
Zy = Iy./(H/2);  % 強軸断面係数
Zz = Iz./(B/2);  % 弱軸断面係数

% スカラップ欠損考慮断面係数
if scallop > 0
  % スカラップによりウェブが欠損し、フィレットも失われる
  hw_eff = (H - 2*tf) - 2*scallop;  % 有効ウェブ高さ
  Iw_eff = tw .* hw_eff.^3 / 12;    % 有効ウェブの断面二次モーメント
  Iy_scallop = 2*If1 + Iw_eff;      % フランジ＋有効ウェブ（フィレットなし）
  Zys = Iy_scallop ./ (H/2);
else
  % スカラップなしの場合はZyと同じ
  Zys = Zy;
end

% フランジのみ断面係数（ウェブ非考慮時用）
Zyf = B.*(H.^3-(H-2*tf).^3)./(6*H);

% 塑性断面係数
Zpy = B.*tf.*(H-tf) + 1/4*tw.*(H-2*tf).^2 + 2*rA.*(H-2*tf-2*rd);
Zpz = 1/2*B.^2.*tf + 1/4*(H-2*tf).*tw.^2 + 2*rA.*(tw+2*rd);

% サンブナンのねじり定数
JJ = ((B.*tf.^3)*2 + ((H-2*tf).*tw.^3))/3;

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, ...
  Aw, Af, Zys];
end

