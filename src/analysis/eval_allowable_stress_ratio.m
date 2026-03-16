function [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij, ...
  fc, fb, fs, kcx, kcy, lamy, lamz, ratio_nominal] = ...
  eval_allowable_stress_ratio(mewfs, st, stc, A, Iy, Iz, C, ...
  mtype, stype, dir_girder, Em, Fm, idm2n, lb, lm, lr, ...
  mejoint, nominal, idmg2ng, idmc2nc, options)

% 共通配列
idm2n1 = idm2n(:,1);
idm2n2 = idm2n(:,2);
lb = lb(:,[1 3 2]);

% 限界細長比の算定
clam = pi*sqrt(Em./(0.6*Fm));

% 許容応力度ft,fsの算定
ft = [Fm/1.5 Fm];
fs = [Fm/(1.5*sqrt(3)) Fm/sqrt(3)];

% 通し部材長さ
lm_nominal = lm;
lm_nominal(mtype==PRM.GIRDER) = ...
  calc_nominal_girder_length(nominal.girder.idmeg, lm(mtype==PRM.GIRDER));
lm_nominal(mtype==PRM.COLUMN) = ...
  calc_nominal_column_length(nominal.column, lm(mtype==PRM.COLUMN));

% 柱の座屈長さ係数の算定
lrm = lm_nominal;
lrm(mtype==PRM.COLUMN) = lrm(mtype==PRM.COLUMN)...
  -max([sum(lr.columnx,2) sum(lr.columny,2)],[],2);
[lkx, lky, kcx, kcy] = calc_buckling_length( ...
  Iy, mtype, idm2n1, idm2n2, dir_girder, lm_nominal, lrm, lb, ...
  Em, mejoint, nominal, idmc2nc, options);
[fc, lamy, lamz] = calc_fc(A, Iy, Iz, clam, mtype, stype, Fm, lkx, lky);

% 曲げ許容応力度の算定
fb = calc_fb(mewfs, C, clam, ft, mtype, stype, lb, options);

% 許容応力度比の算定
[ratio_nominal, fc] = calc_nominal_allowable_stress_ratio(...
  st, stc, ft, fc, fb, fs, nominal);

% 制約値の計算
[gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij] = ...
  calc_nominal_stress_constraints(ratio_nominal, nominal);

return
end
