function [congdef, deflection_angle] = ...
calc_girder_deflection(Eg, lg, M0g, Mcg, Iyg, gdmax)

% たわみ計算
% dbl = 1/15*lg./H-1;
delta = 5*M0g.*lg.^2./(48*Eg.*Iyg)-Mcg./(16*Eg.*Iyg).*lg.^2;
deflection_angle = delta./lg;
congdef = delta./lg*gdmax-1;
return
end
