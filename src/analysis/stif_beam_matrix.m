function ke = stif_beam_matrix(...
  L0, A, Asy, Asz, Iy, Iz, J, E, pr, lry, lrz, joint, kcb, flag)

% 入力値のチェック
if any(isnan([L0, A, Asy, Asz, Iy, Iz, J, E, pr]))
  fprintf('エラー: stif_beam_matrix入力にNaN\n');
  fprintf('  L0=%.3e, A=%.3e, Asy=%.3e, Asz=%.3e\n', ...
    L0, A, Asy, Asz);
  fprintf('  Iy=%.3e, Iz=%.3e, J=%.3e\n', Iy, Iz, J);
  fprintf('  E=%.3e, pr=%.3f\n', E, pr);
  fprintf('  lry=[%.3f, %.3f], lrz=[%.3f, %.3f]\n', ...
    lry(1), lry(2), lrz(1), lrz(2));
  % error('入力パラメータにNaNが含まれています');
end

% 計算の準備
ke = zeros(12, 12);
Ly = L0-lry(1)-lry(2);
Lz = L0-lrz(1)-lrz(2);

% 長さチェック
if Ly <= 0 || Lz <= 0
  fprintf(['警告: 有効長さが0以下です ' ...
    '(L0=%.3f, Ly=%.3f, Lz=%.3f)\n'], L0, Ly, Lz);
  fprintf('  lry=[%.3f, %.3f], lrz=[%.3f, %.3f]\n', ...
    lry(1), lry(2), lrz(1), lrz(2));
end
G = E/(2*(1+pr));
if flag.consider_shear_deformation
  if Asy>0
    ry = 6*E*Iy/(G*Asy*Ly^2);
  else
    ry = 0;
  end
  if Asz>0
    rz = 6*E*Iz/(G*Asz*Lz^2);
  else
    rz = 0;
  end
  if ~isempty(kcb)
    k1y = kcb*Ly/(4*E*Iy);
    k2y = 1.d6*kcb*Ly/(4*E*Iy);
    k1z = kcb*Lz/(4*E*Iz);
    k2z = 1.d6*kcb*Lz/(4*E*Iz);
  else
    k1y = 1.d6;
    k2y = 1.d6;
    k1z = 1.d6;
    k2z = 1.d6;
    % k1y = 1.d6*Ly/(4*E*Iy);
    % k2y = 1.d6*Ly/(4*E*Iy);
    % k1z = 1.d6*Lz/(4*E*Iz);
    % k2z = 1.d6*Lz/(4*E*Iz);
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
else
  ry = 0;
  rz = 0;
end
J = J/100;

if flag.consider_shear_deformation
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
else
  csy = 1;
  cbsy1 = 1;
  cbsy2 = 1;
  cb1y1 = 1;
  cb1y2 = 1;
  cb2y = 1;
  csz = 1;
  cbsz1 = 1;
  cbsz2 = 1;
  cb1z1 = 1;
  cb1z2 = 1;
  cb2z = 1;
end

% --- kn ---
kn = E*A/L0;
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
