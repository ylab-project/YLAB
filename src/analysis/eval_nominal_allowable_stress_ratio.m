function [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij, ...
  fcn, fbn, fsn, kcx, kcy, lamy, lamz, ration] = ...
  eval_nominal_allowable_stress_ratio(mewfs, stn, stcn, A, Iy, Iz, C, ...
  mtype, stype, dir_girder, Em, Fm, idm2n, lb, lmn, lr, ...
  mejoint, nominal, isgmirrored, idmg2ng, idmc2nc, options)

% 共通配列
nmtype = nominal.property.mtype;
idnm2m = nominal.property.idme;
idm2n1 = idm2n(:,1);
idm2n2 = idm2n(:,2);
% lb = lb(:,[1 3 2]);

% 限界細長比の算定
clam = pi*sqrt(Em./(0.6*Fm));

% 許容応力度ft,fsの算定
ft = [Fm/1.5 Fm];
fs = [Fm/(1.5*sqrt(3)) Fm/sqrt(3)];

% 柱の座屈長さ係数の算定
lrm = [lmn lmn];
lrm(mtype==PRM.COLUMN,:) = lrm(mtype==PRM.COLUMN,:)...
  -[sum(lr.columnx,2) sum(lr.columny,2)];
[lkx, lky, kcx, kcy] = calc_buckling_length( ...
  Iy, mtype, idm2n1, idm2n2, dir_girder, lmn, lrm, lb, ...
  Em, mejoint, nominal, idmc2nc, options);
[fc, lamy, lamz] = calc_fc(A, Iy, Iz, clam, mtype, stype, Fm, lkx, lky);

% 曲げ許容応力度の算定
fb = calc_fb(mewfs, C, clam, ft, mtype, stype, lb, options);

% 移し替え
ftn = ft(idnm2m(:,1),:);
fcn = fc(idnm2m(:,1),:,:);
fbn = fb(idnm2m(:,1),:,:);
fsn = fs(idnm2m(:,1),:);

% 許容応力度比の算定
[ration, fcn] = calc_nominal_allowable_stress_ratio(...
  stn, stcn, ftn, fcn, fbn, fsn, nmtype);

% 制約値の計算
[gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij] = ...
  calc_nominal_stress_constraints(ration, nominal);

% ミラー配置
ngsub = nominal.girder.idsub(:,2);
[gri, grj, gsi, gsj] = mirror_arrangement(...
  isgmirrored, idmg2ng, ngsub, gri, grj, gsi, gsj);
return
end

%--------------------------------------------------------------------------
function [gri, grj, gsi, gsj] = mirror_arrangement(...
  isgmirrored, idmg2ng, ngsub, gri, grj, gsi, gsj)

% 計算準備
ng = length(isgmirrored);
[nng, nlc] = size(gri);
istarget = false(1,nng);
for ig=1:ng
  ing = idmg2ng(ig);
  if ngsub(ing)>1
    %TODO：処理方法がわからないので保留
    continue
  end
  if isgmirrored(ig)
    istarget(ing) = true;
  end
end

% gr
tmp = gri(istarget,:);
gri(istarget,:) = grj(istarget,:);
grj(istarget,:) = tmp;

% gr
tmp = gsi(istarget,:);
gsi(istarget,:) = gsj(istarget,:);
gsj(istarget,:) = tmp;
return
end