function r = calc_shear_deformation_ratio(E, I, G, As, L)
%calc_shear_deformation_ratio - せん断変形係数を算定
%
%   r = calc_shear_deformation_ratio(E, I, G, As, L) は、曲げ剛性と
%   せん断剛性から梁要素の無次元せん断変形係数を算定する。
%
%   入力引数:
%     E  - ヤング係数 (N/mm2)
%     I  - 断面二次モーメント (mm4)
%     G  - せん断弾性係数 (N/mm2)
%     As - せん断断面積 (mm2)
%     L  - 曲げに対する可撓長さ (mm)
%
%   出力引数:
%     r - せん断変形係数

if As > 0
  r = 6*E*I/(G*As*L^2);
else
  r = 0;
end

return
end
