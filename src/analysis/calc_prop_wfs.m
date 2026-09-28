function section_property = calc_prop_wfs(secdim, scallop)
%calc_prop_wfs - H形鋼の断面性能と端部の断面係数を計算する
%
%   section_property = calc_prop_wfs(secdim, scallop) は、全断面と
%   スカラップ控除後、フランジのみの断面性能を計算する。
%   強軸・弱軸ともウェブ考慮の指定に対応する断面係数を返す。
%
%   入力引数:
%     secdim  - 断面寸法 [H, B, tw, tf, r] (mm)
%     scallop - スカラップ寸法 (mm)、省略時は0
%
%   出力引数:
%     section_property - 断面性能 [n×20]
%       [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw, Af,
%        Zysc, Iyr, Asc, Zzsc, Zzf, kappay, kappaz]
%       Zy/Zzは全断面、Zysc/Zzscはスカラップ控除後、Zyf/Zzfは
%       フランジのみの断面係数（局所y軸が強軸）
%       Asy/Aszは各軸まわりの曲げに対応する剛性用せん断面積で、
%       せん断形状係数kappay/kappazで除した値
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
Aw = (H-2*tf-2*scallop).*tw;     % ウェブ断面積（スカラップ考慮）
Af = B.*tf*2;                    % フランジ断面積
% SS7計算編3.2.5：強軸はウェブ、弱軸は両フランジをκで除す
kappay = ones(size(H));          % 強軸のせん断形状係数
kappaz = 1.2*ones(size(H));      % 弱軸のせん断形状係数
Asy = (H-2*tf).*tw;              % 強軸曲げのせん断面積
Asz = Af./kappaz;                % 弱軸曲げのせん断面積

% 強軸（y軸）まわりの断面二次モーメント
If1 = B.*tf.^3/12 + B.*tf.*(H-tf).^2/4;  % フランジ
Iw1 = tw.*(H-2*tf).^3/12;                 % ウェブ
Ir1 = rI+rA.*((H-2*tf)/2-rd).^2;          % フィレット
Iy = 2*If1 + Iw1 + 4*Ir1;
Iyr = 2*If1 + Iw1;              % フィレット無視

% 弱軸（z軸）まわりの断面二次モーメント
If2 = tf.*B.^3/12;                        % フランジ
Iw2 = (H-2*tf).*tw.^3/12;                 % ウェブ
Ir2 = rI+rA.*(tw/2+rd).^2;                % フィレット
Iz = 2*If2 + Iw2 + 4*Ir2;

% 断面係数（欠損なし）
Zy = Iy./(H/2);  % 強軸断面係数
Zz = Iz./(B/2);  % 弱軸断面係数

% スカラップ欠損考慮断面係数・断面積
if scallop > 0
  % スカラップによりウェブが欠損し、フィレットも失われる
  hw_eff = (H - 2*tf) - 2*scallop;  % 有効ウェブ高さ
  Iw_eff = tw .* hw_eff.^3 / 12;
  Iy_scallop = 2*If1 + Iw_eff;
  Zysc = Iy_scallop ./ (H/2);
  Zzsc = (2*If2 + hw_eff.*tw.^3/12)./(B/2);
  Asc = 2*B.*tf + tw.*hw_eff;  % スカラップ考慮断面積
else
  Zysc = Zy;
  Zzsc = Zz;
  Asc = A;
end

% フランジのみ断面係数（ウェブ非考慮時用）
Zyf = B.*(H.^3-(H-2*tf).^3)./(6*H);
Zzf = 2*If2./(B/2);

% 塑性断面係数
Zpy = B.*tf.*(H-tf) + 1/4*tw.*(H-2*tf).^2 + 2*rA.*(H-2*tf-2*rd);
Zpz = 1/2*B.^2.*tf + 1/4*(H-2*tf).*tw.^2 + 2*rA.*(tw+2*rd);

% サンブナンのねじり定数
JJ = ((B.*tf.^3)*2 + ((H-2*tf).*tw.^3))/3;

% 断面性能の配列化
section_property = [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, ...
  JJ, Aw, Af, Zysc, Iyr, Asc, Zzsc, Zzf, kappay, kappaz];

return
end

