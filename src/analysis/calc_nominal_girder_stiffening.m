function [conslr, slratio] = calc_nominal_girder_stiffening(...
  msdim, A, Iz, Zy, Zpy, lbn, lnm, F, slr, mstype, nominal, idm2nm)

% 定数
nm = size(msdim,1);

% 対象の絞り込み（H形梁部材）
iswfs = false(nm,1);
idng2m = nominal.property.idme(nominal.property.mtype==PRM.GIRDER,1);
iswfs(idng2m) = true;
iswfs = iswfs&(mstype==PRM.WFS);

% 計算の準備
ng = nnz(iswfs);
Ag = A(iswfs);
Izg = Iz(iswfs);
Zyg = Zy(iswfs);
Zpyg = Zpy(iswfs);
Fg = F(iswfs);
lng = lnm(iswfs);
lbng = lbn(idm2nm,:); lbng = lbng(iswfs,:);
msdimg = msdim(iswfs,:);

% 細長比
iy = sqrt(Izg./Ag); 
lamy = lng./iy;

%  --- 均等配置 ---
ppp = zeros(ng,1); ppp(Fg==235) = 170; ppp(Fg==325) = 130;
nreq = max(ceil((lamy-ppp)/20),0);
lbreq1 = (ppp+20*nreq).*iy./(nreq+1);
lbmax = lbng(:,3);

% 非対象部材を除外
% istarget = all(slr.istarget,2);
% lbreq1(~istarget) = 0;

% --- 端部配置 ---
alfa = zeros(ng,1); alfa(Fg==235) = 1.2; alfa(Fg==325) = 1.1;
cc1 = zeros(ng,1); cc1(Fg==235) = 250; cc1(Fg==325) = 200;
cc2 = zeros(ng,1); cc2(Fg==235) = 65; cc2(Fg==325) = 50;
Hg = msdimg(:,1);
Afg = msdimg(:,2).*msdimg(:,4);
lbmy = 0.5*lng.*(1-Zyg./(alfa.*Zpyg));
lbreq2 = min([cc1.*Afg./Hg cc2.*iy],[],2);

% ピン
lbmy = [lbmy lbmy];
lblr = max(slr.lb(:,1:2),[],2);

% 非対象部材を除外
istarget = any(slr.istarget,2);
lbreq2(~istarget) = 0;

try
  % lbmax <= lbreq1   or [lbl lbr] <= lbreq2
  %                   <-> 
  % lbreq1/lbmax >= 1 or lbreq2/[lbl lbr] >= 1
  rrr1 = lbreq1./lbmax;
  rrr2 = lbreq2./lblr;
  conslr = 1-max([rrr1 rrr2],[],2);
  conslr(isinf(conslr)) = -1;
catch ME
  disp(ME.message);
  error('梁の鋼材種別が400級または490級以外です.');
end

% 非対象部材を除外
istarget = any(slr.istarget,2);
conslr(~istarget) = -1;

% 出力用
if nargout==2
  slratio.n = zeros(ng,1);
  slratio.lg = lmg;
  slratio.lb = slr.lb;
  slratio.lambda = lamy;
  slratio.nreq = nreq;
  slratio.lbreq1 = lbreq1;
  slratio.lbreq2 = lbreq2;
  slratio.lbmy = lbmy;
end
return
end
