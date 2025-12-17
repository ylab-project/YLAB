function ke = estfsfs(L, A, Asy, Asz, Iy, Iz, J, E, pr, flag)
% Element stiffness matrix in local coordinates;
% member of space frame considering shear deformation

% Initialization and parameter setting
ke = zeros(12, 12);
G = E/(2*(1+pr));
if flag.consider_shear_deformation
  ry = 6*E*Iy/(G*Asy*L^2);
  rz = 6*E*Iz/(G*Asz*L^2);
else
  ry = 0;
  rz = 0;
end
J = J/100;

% 係数
ay = 3*(2+ry)/((2+ry)^2-(1-ry)^2);
az = 3*(2+rz)/((2+rz)^2-(1-rz)^2);
by = 3*(1-ry)/((2+ry)^2-(1-ry)^2);
bz = 3*(1-rz)/((2+rz)^2-(1-rz)^2);
cy = (ay+by)/3;
cz = (az+bz)/3;

% --- kn ---
kn = E*A/L;
ke(1,1) = kn;
ke(1,7) = -kn;
ke(7,7) = kn;
%
ke(7,1) = -kn;

% --- kt ---
kt = G*J/L;
ke(4,4) = kt;
ke(4,10) = -kt;
ke(10,10) = kt;
%
ke(10,4) = -kt;

% --- ksy ---
ksy = (12*E*Iy/L^3)*cy;
ke(3,3) = ksy;
ke(3,9) = -ksy;
ke(9,9) = ksy;
%
ke(9,3) = -ksy;

% --- kbsy ---
kbsy = (6*E*Iy/L^2)*cy;
ke(3,5) = -kbsy;
ke(3,11) = -kbsy;
ke(5,9) = kbsy;
ke(9,11) = kbsy;
%
ke(5,3) = -kbsy;
ke(11,3) = -kbsy;
ke(9,5) = kbsy;
ke(11,9) = kbsy;

% --- kb1y ---
kby1 = (4*E*Iy/L)*(ay/2);
ke(5,5) = kby1;
ke(11,11) = kby1;

% --- kb2y ---
kb2y = (2*E*Iy/L)*by;
ke(5,11) = kb2y;
%
ke(11,5) = kb2y;

% --- ksz ---
ksz = (12*E*Iz/L^3)*cz;
ke(2,2) = ksz;
ke(2,8) = -ksz;
ke(8,8) = ksz;
%
ke(8,2) = -ksz;

% --- kbsz ---
kbsz = (6*E*Iz/L^2)*cz;
ke(2,6) = kbsz;
ke(2,12) = kbsz;
ke(6,8) = -kbsz;
ke(8,12) = -kbsz;
%
ke(6,2) = kbsz;
ke(12,2) = kbsz;
ke(8,6) = -kbsz;
ke(12,8) = -kbsz;

% --- kb1z ---
kb1z = (4*E*Iz/L)*(az/2);
ke(6,6) = kb1z;
ke(12,12) = kb1z;

% --- kb2z ---
kb2z = (2*E*Iz/L)*bz;
ke(6,12) = kb2z;
ke(12,6) = kb2z;

% sym.
% ke = ke+tril(ke,-1)';
return
end
