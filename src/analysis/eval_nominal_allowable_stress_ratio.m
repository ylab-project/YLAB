function [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, ...
  bnij, fcn, fbn, fsn, ftn, kcx, kcy, lkx, lky, ...
  ration, bkinfo, lnm_bk] = ...
  eval_nominal_allowable_stress_ratio(msdim, stn, stcn, ...
  A, Iy, Iz, C, mtype, stype, dir_girder, Em, Fm, ...
  idm2n, lb, lm, lnm, lr, mejoint, nominal, ...
  isgmirrored, idmg2ng, idmc2nc, options, beta, lcdir, ...
  col_idstory, onfg_x, onfg_y)
%eval_nominal_allowable_stress_ratio - 許容応力度比の算定
%
%   方向別に calc_buckling_length を2回呼び出し、
%   柱座屈長さ係数と許容応力度比を算定する。
%
%   入力引数:
%     lm     - 芯間距離（元の部材長）[nme×1]
%     lnm    - 通し部材長 [nme×1]
%     lr     - 剛域長 (struct)
%     lb     - 補剛間隔配列 [nme×3]
%     onfg_x - X方向基礎梁接続フラグ [nmc×1]
%     onfg_y - Y方向基礎梁接続フラグ [nmc×1]
%     （その他は従来と同じ）

% 共通配列
nme = length(mtype);
nmtype = nominal.property.mtype;
idnm2m = nominal.property.idme;
idm2n1 = idm2n(:,1);
idm2n2 = idm2n(:,2);

% 限界細長比の算定
clam = pi*sqrt(Em./(0.6*Fm));

% 許容応力度ft,fsの算定
ft = [Fm/1.5 Fm];
fs = [Fm/(1.5*sqrt(3)) Fm/sqrt(3)];

% 座屈解析用名目部材長（通し柱長−方向別Σlr）
lnm_bk = calc_nominal_column_length_for_buckling(lnm, lr, ...
  mtype, idmc2nc, nominal.column);

% 方向別入力の準備
dir_full = zeros(nme, 1);
dir_full(mtype==PRM.GIRDER) = dir_girder;
is_gx = dir_full==PRM.X | dir_full==PRM.XY;
is_gy = dir_full==PRM.Y | dir_full==PRM.XY;
ilc_x = lcdir==PRM.EXP | lcdir==PRM.EXN;
ilc_y = lcdir==PRM.EYP | lcdir==PRM.EYN;

% X方向の座屈長さ係数
[lk_x, kcx, bkinfox] = calc_buckling_length(Iy, ...
  mtype, idm2n1, idm2n2, is_gx, lnm, lm, lr.columnx, ...
  Em, mejoint(:,[1 2]), nominal, idmc2nc, options, ...
  beta, ilc_x, col_idstory, onfg_x);

% Y方向の座屈長さ係数
[lk_y, kcy, bkinfoy] = calc_buckling_length(Iy, ...
  mtype, idm2n1, idm2n2, is_gy, lnm, lm, lr.columny, ...
  Em, mejoint(:,[3 4]), nominal, idmc2nc, options, ...
  beta, ilc_y, col_idstory, onfg_y);

% 座屈長さの組み立て
lkx = lk_x;
lky = zeros(nme, 3);
lky(:,1) = lk_y;
lky(mtype==PRM.GIRDER,:) = lb(mtype==PRM.GIRDER,:);

% bkinfo のマージ（既存フィールド名を保持）
bkinfo.IcLc = bkinfox.IcLc;
bkinfo.sumIcTop = bkinfox.sumIcTop;
bkinfo.sumIcBot = bkinfox.sumIcBot;
bkinfo.sumIgTopX = bkinfox.sumIgTop;
bkinfo.sumIgBotX = bkinfox.sumIgBot;
bkinfo.sumIgTopY = bkinfoy.sumIgTop;
bkinfo.sumIgBotY = bkinfoy.sumIgBot;
bkinfo.GAx = bkinfox.GA;
bkinfo.GBx = bkinfox.GB;
bkinfo.GAy = bkinfoy.GA;
bkinfo.GBy = bkinfoy.GB;
bkinfo.kcxRaw = bkinfox.kcRaw;
bkinfo.kcyRaw = bkinfoy.kcRaw;
bkinfo.kcx = bkinfox.kc;
bkinfo.kcy = bkinfoy.kc;
bkinfo.lbcnmaxX = bkinfox.lbcnmax;
bkinfo.lbcnmaxY = bkinfoy.lbcnmax;

% 許容圧縮応力度の算定
fc = calc_fc(A, Iy, Iz, clam, mtype, stype, Fm, lkx, lky);

% 曲げ許容応力度の算定
mewfs = msdim(stype==PRM.WFS,:);
fb = calc_fb(mewfs, C, clam, ft, mtype, stype, lb, options);

% 移し替え
ftn = ft(idnm2m(:,1),:);
fcn = fc(idnm2m(:,1),:,:);
fbn = fb(idnm2m(:,1),:,:);
fsn = fs(idnm2m(:,1),:);

% 許容応力度比の算定
[ration, fcn] = calc_nominal_allowable_stress_ratio(...
  stn, stcn, ftn, fcn, fbn, fsn, nmtype);

% TB応力比の上書き（N/Ta）
ration = calc_nominal_allowable_stress_ratio_tension_brace(...
  ration, stn, nominal, stype, A, msdim);

% 制約値の計算
[gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij] = ...
  calc_nominal_stress_constraints(ration, nominal);

% ミラー配置
ngsub = nominal.girder.idsub(:,2);
[gri, grj, gsi, gsj] = mirror_arrangement(isgmirrored, ...
  idmg2ng, ngsub, gri, grj, gsi, gsj);

return
end

%----------------------------------------------------------
function [gri, grj, gsi, gsj] = mirror_arrangement( ...
  isgmirrored, idmg2ng, ngsub, gri, grj, gsi, gsj)
%mirror_arrangement - ミラー配置梁のi端j端応力比入替
%
%   [gri, grj, gsi, gsj] = mirror_arrangement(
%     isgmirrored, idmg2ng, ngsub, gri, grj,
%     gsi, gsj) は、
%   ミラー配置の梁についてi端j端の応力比を入替える。
%
%   入力引数:
%     isgmirrored - ミラーフラグ [ng×1]
%     idmg2ng     - 梁→公称梁番号 [ng×1]
%     ngsub       - サブ部材数 [nng×1]
%     gri, grj    - i/j端曲げ応力比 [nng×ncol]
%     gsi, gsj    - i/j端せん断応力比 [nng×ncol]
%
%   出力引数:
%     gri, grj - 入替後の曲げ応力比
%     gsi, gsj - 入替後のせん断応力比

% 計算準備
ng = length(isgmirrored);
nng = size(gri, 1);
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

% gs
tmp = gsi(istarget,:);
gsi(istarget,:) = gsj(istarget,:);
gsj(istarget,:) = tmp;

return
end
