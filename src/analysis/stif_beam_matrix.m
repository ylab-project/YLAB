function ke = stif_beam_matrix(L0, A, Asy, Asz, Iy, Iz, J, E, G, ...
  lry, lrz, lrn, joint, kcb, flag)
%stif_beam_matrix - 材軸方向と曲げ方向の剛域を考慮した剛性を算定
%
%   ke = stif_beam_matrix(L0, A, Asy, Asz, Iy, Iz, J, E, G, ...
%     lry, lrz, lrn, joint, kcb, flag) は、材軸方向と曲げ方向で
%   異なる有効長を用いて梁柱要素の局所剛性行列を算定する。
%
%   入力引数:
%     L0    - 構造心間の部材長 (mm)
%     A     - 軸変形用断面積 (mm2)
%     Asy   - 局所Y方向のせん断断面積 (mm2)
%     Asz   - 局所Z方向のせん断断面積 (mm2)
%     Iy    - 局所Y軸回りの断面二次モーメント (mm4)
%     Iz    - 局所Z軸回りの断面二次モーメント (mm4)
%     J     - ねじり定数 (mm4)
%     E     - ヤング係数 (N/mm2)
%     G     - せん断弾性係数 (N/mm2)
%     lry   - 局所Y軸回り曲げ用の両端剛域長 [1 x 2] (mm)
%     lrz   - 局所Z軸回り曲げ用の両端剛域長 [1 x 2] (mm)
%     lrn   - 材軸方向の両端剛域長 [1 x 2] (mm)
%     joint - 両端の結合状態 [1 x 4]
%     kcb   - 局所Y/Z軸回りの柱脚回転剛性 [1 x 2] (N.mm/rad)
%             Infは固定。jointのピン指定を優先する。
%     flag  - 解析条件構造体
%
%   出力引数:
%     ke - 局所剛性行列 [12 x 12]

% 計算の準備
ke = zeros(12, 12);
Ln = L0-lrn(1)-lrn(2);
Ly = L0-lry(1)-lry(2);
Lz = L0-lrz(1)-lrz(2);

% せん断変形の考慮によらず、結合状態と柱脚ばねを反映する。
if flag.consider_shear_deformation
  ry = calc_shear_deformation_ratio(E, Iy, G, Asy, Ly);
  rz = calc_shear_deformation_ratio(E, Iz, G, Asz, Lz);
else
  ry = 0;
  rz = 0;
end

% 固定端は部材曲げ剛性の1e6倍で近似する。
% 柱頭側の固定剛性は柱脚ばねの大小に依存させない。
k1y = 1.d6;
k2y = 1.d6;
k1z = 1.d6;
k2z = 1.d6;
if isfinite(kcb(1))
  k1y = kcb(1)*Ly/(4*E*Iy);
end
if isfinite(kcb(2))
  k1z = kcb(2)*Lz/(4*E*Iz);
end
if joint(1) == PRM.PIN
  k1y = 0;
end
if joint(2) == PRM.PIN
  k2y = 0;
end
if joint(3) == PRM.PIN
  k1z = 0;
end
if joint(4) == PRM.PIN
  k2z = 0;
end
ky = 2*(k1y+1)*(k2y+1)-0.5+ry*(4*k1y*k2y+k1y+k2y);
kz = 2*(k1z+1)*(k2z+1)-0.5+rz*(4*k1z*k2z+k1z+k2z);
csy = (4*k1y*k2y+k1y+k2y)/(2*ky);
cbsy1 = (2*k1y*k2y+k1y)/ky;
cbsy2 = (2*k1y*k2y+k2y)/ky;
cb1y1 = (4*k1y*k2y*(1+ry/2)+3*k1y)/(2*ky);
cb1y2 = (4*k1y*k2y*(1+ry/2)+3*k2y)/(2*ky);
cb2y = (2*k1y*k2y*(1-ry))/ky;
csz = (4*k1z*k2z+k1z+k2z)/(2*kz);
cbsz1 = (2*k1z*k2z+k1z)/kz;
cbsz2 = (2*k1z*k2z+k2z)/kz;
cb1z1 = (4*k1z*k2z*(1+rz/2)+3*k1z)/(2*kz);
cb1z2 = (4*k1z*k2z*(1+rz/2)+3*k2z)/(2*kz);
cb2z = (2*k1z*k2z*(1-rz))/kz;

% --- kn ---
kn = E*A/Ln;
ke(1,1) = kn;
ke(1,7) = -kn;
ke(7,7) = kn;
%
ke(7,1) = -kn;

% --- kt ---
kt = G*J/L0;
ke(4,4) = kt;
ke(4,10) = -kt;
ke(10,10) = kt;
%
ke(10,4) = -kt;

% --- ksy ---
ksy = (12*E*Iy/Ly^3)*csy;
ke(3,3) = ksy;
ke(3,9) = -ksy;
ke(9,9) = ksy;
ke(9,3) = -ksy;

% --- kbsy ---
kbsy = (6*E*Iy/Ly^2);
kbsy1 = kbsy*cbsy1;
ke(3,5) = -kbsy1;
ke(5,9) = kbsy1;
ke(5,3) = -kbsy1;
ke(9,5) = kbsy1;
kbsy2 = kbsy*cbsy2;
ke(3,11) = -kbsy2;
ke(9,11) = kbsy2;
ke(11,3) = -kbsy2;
ke(11,9) = kbsy2;

% --- kb1y ---
kb1y = 4*E*Iy/Ly;
kb1y1 = kb1y*cb1y1;
ke(5,5) = kb1y1;
kb1y2 = kb1y*cb1y2;
ke(11,11) = kb1y2;

% --- kb2y ---
kb2y = (2*E*Iy/Ly)*cb2y;
ke(5,11) = kb2y;
ke(11,5) = kb2y;

% --- ksz ---
ksz = (12*E*Iz/Lz^3)*csz;
ke(2,2) = ksz;
ke(2,8) = -ksz;
ke(8,8) = ksz;
ke(8,2) = -ksz;

% --- kbsz ---
kbsz = 6*E*Iz/Lz^2;
kbsz1 = kbsz*cbsz1;
ke(2,6) = kbsz1;
ke(6,8) = -kbsz1;
ke(6,2) = kbsz1;
ke(8,6) = -kbsz1;
kbsz2 = kbsz*cbsz2;
ke(2,12) = kbsz2;
ke(8,12) = -kbsz2;
ke(12,2) = kbsz2;
ke(12,8) = -kbsz2;

% --- kb1z ---
kb1z = 4*E*Iz/Lz;
kb1z1 = kb1z*cb1z1;
ke(6,6) = kb1z1;
kb1z2 = kb1z*cb1z2;
ke(12,12) = kb1z2;

% --- kb2z ---
kb2z = (2*E*Iz/Lz)*cb2z;
ke(6,12) = kb2z;
ke(12,6) = kb2z;

return
end
