function [conslr, slratio] = calc_girder_stiffening(...
  sdimg, Ag, Izg, Zyg, Zpyg, lbg, lmg, Fg, slr)

% 計算の準備
ng = length(Ag);
iy = sqrt(Izg./Ag);
lam_y = lmg./iy;

%  --- 均等配置 ---
ppp = zeros(ng,1); ppp(Fg==235) = 170; ppp(Fg==325) = 130;
nreq = max(ceil((lam_y-ppp)/20),0);
lbreq1 = (ppp+20*nreq).*iy./(nreq+1);
lbmax = lbg(:,3);

% 非対象部材を除外
istarget = all(slr.istarget,2);
lbreq1(~istarget) = 0;

% --- 端部配置 ---
alfa = zeros(ng,1); alfa(Fg==235) = 1.2; alfa(Fg==325) = 1.1;
cc1 = zeros(ng,1); cc1(Fg==235) = 250; cc1(Fg==325) = 200;
cc2 = zeros(ng,1); cc2(Fg==235) = 65; cc2(Fg==325) = 50;
Hg = sdimg(:,1);
Afg = sdimg(:,2).*sdimg(:,4);
lbmy = 0.5*lmg.*(1-Zyg./(alfa.*Zpyg));
lbreq2 = min([cc1.*Afg./Hg cc2.*iy],[],2);
% iyreq2 = lblr./cc2;
% slcr2 = cc1./lblr;

% ピン
lbmy = [lbmy lbmy];
lblr = max(slr.lb(:,1:2),[],2);

% 非対象部材を除外
istarget = any(slr.istarget,2);
lbreq2(~istarget) = 0;

try
  % lbmax <= lbreq1 or [lbl lbr] <= lbreq2
  % <-> lbreq1/lbmax >= 1 or lbreq2/[lbl lbr] >= 1
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

% % 両側ピンを除外
% ispin = all(jointg(:,1:2)==PRM.PIN,2);
% lbreq1(ispin) = inf;
% lbreq2(ispin) = inf;
% conslr(idgs) = -1;

% % 通し梁の判定
% for i=1:size(igthrough,1)
%   idgs = igthrough(i,:);
%   idgs(idgs==0) = [];
% 
%   % TODO:RC梁の除外
%   if idgs(1)>ng
%     continue
%   end
%   ispin = all([jointg(idgs(1),1) jointg(idgs(end),2)]==PRM.PIN);
%   if ispin
%     lbreq1(idgs) = inf;
%     lbreq2(idgs) = inf;
%     conslr(idgs) = -1;
%   end
% end

% 出力用
if nargout==2
  slratio.n = zeros(ng,1);
  slratio.lg = lmg;
  slratio.lb = slr.lb;
  slratio.lambda = lam_y;
  slratio.nreq = nreq;
  slratio.lbreq1 = lbreq1;
  slratio.lbreq2 = lbreq2;
  slratio.lbmy = lbmy;
  % % 復元用：次の条件を満たす必要あり
  % %   "iy>=iyreq1" 
  % %   または 
  % %   "iy>=iyreq2かつH/Btf<slcr2"
  % slratio.iyreq1 = iyreq1;
  % slratio.iyreq2 = iyreq2;
  % slratio.slcr2 = slcr2;
end
return
end
