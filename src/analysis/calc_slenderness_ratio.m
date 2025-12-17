function [consr, slratio] = calc_slenderness_ratio(Ag, Izg, lbg, lmg, Fg)
iy = sqrt(Izg./Ag);
lam_y = lmg./iy;
nnn = lmg./lbg-1;
ppp = zeros(length(Ag),1);
ppp(Fg==235) = 170;
ppp(Fg==325) = 130;
try
  consr = lam_y./(ppp+20*nnn)-1;
catch ME
  disp(ME.message);
  error('梁の鋼材種別が400級または490級以外です.');
end

% 出力用
if nargout==2
  slratio.n = nnn;
  slratio.lg = lmg;
  slratio.lb = lbg;
  slratio.lambda = lam_y;
  nreq = max(ceil((lam_y-ppp)/20),0);
  slratio.iyreq = lmg./(ppp+20*nnn);
  slratio.nreq = nreq;
end
return
end
