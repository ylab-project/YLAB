function [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij, ...
  fcn, fbn, fsn, ftn, kcx, kcy, lkx, lky, ration, bkinfo, ...
  id_center_sel] = eval_nominal_allowable_stress_ratio(msdim, ...
  stn, stcn, A, Iy, Iz, C, mtype, stype, dir_girder, Em, Fm, ...
  idm2n, lb, lm, lnm, mejoint, nominal, isgmirrored, idmg2ng, ...
  idmc2nc, options, beta, lcdir, col_idstory, onfg_x, onfg_y, ...
  Cn, nomgc, column_buckling_K)
%eval_nominal_allowable_stress_ratio - 名目部材の許容応力度比を算定する
%
%   [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij,
%     fcn, fbn, fsn, ftn, kcx, kcy, lkx, lky, ration,
%     bkinfo, id_center_sel] =
%     eval_nominal_allowable_stress_ratio(msdim, stn,
%     stcn, A, Iy, Iz, C, mtype, stype, dir_girder, Em,
%     Fm, idm2n, lb, lm, lnm, mejoint, nominal,
%     isgmirrored, idmg2ng, idmc2nc, options, beta,
%     lcdir, col_idstory, onfg_x, onfg_y, Cn, nomgc) は、
%   方向別に calc_buckling_length を2回呼び出して柱座屈長さ
%   係数を算定し、許容応力度および各端部の許容応力度比を返す。
%
%   入力引数:
%     msdim       - 部材断面寸法 [nme×ndim]
%     stn         - 名目部材の応力 [nnm×ncomp×nlc]
%     stcn        - 名目梁中央モーメント [nng×nlc]
%     A           - 断面積 [nme×1]
%     Iy, Iz      - 断面2次モーメント [nme×1]
%     C           - ねじり定数等 (struct)
%     mtype       - 部材タイプ [nme×1]
%     stype       - 断面タイプ [nme×1]
%     dir_girder  - 梁の方向 [ng×1]
%     Em          - ヤング係数 [nme×1]
%     Fm          - 基準強度 [nme×1]
%     idm2n       - 部材→節点番号 [nme×2]
%     lb          - 補剛間隔配列 [nme×3]
%     lm          - 芯間距離（元の部材長）[nme×1]
%     lnm         - 通し部材長 [nme×1]
%     mejoint     - 部材端接合条件 [nme×4]
%     nominal     - 名目部材情報 (struct)
%     isgmirrored - 梁ミラーフラグ [ng×1]
%     idmg2ng     - 梁→名目梁番号 [ng×1]
%     idmc2nc     - 柱→名目柱番号 [nmc×2]
%     options     - 計算オプション (struct)
%     beta        - ブレース水平力分担率 [nst×nlc]
%     lcdir       - 荷重ケース方向 [nlc×1]
%     col_idstory - 柱の層番号 [nmc×1]
%     onfg_x      - X方向基礎梁接続フラグ [nmc×1]
%     onfg_y      - Y方向基礎梁接続フラグ [nmc×1]
%     Cn          - 名目梁中央係数 (struct)
%     nomgc       - 名目梁中央データ (struct)
%     column_buckling_K - 柱座屈長さ係数の直接入力値 (struct)
%                         .Kx, .Ky [nmec×1]（NaN=自動計算）
%
%   出力引数:
%     gri, grj, grc - 梁i/j端・中央の曲げ応力比 [nng×ncomb]
%     cri, crj      - 柱i/j端の曲げ応力比 [nnc×ncomb]
%     gsi, gsj      - 梁i/j端のせん断応力比 [nng×ncomb]
%     csi, csj      - 柱i/j端のせん断応力比 [nnc×ncomb]
%     bnij          - ブレース軸力比 [nnb×ncomb]
%     fcn, fbn      - 許容圧縮・曲げ応力度 [nnm×npos×nlc]
%     fsn, ftn      - 許容せん断・引張応力度 [nnm×2]
%     kcx, kcy      - X/Y方向の座屈長さ係数 [nmc×1]
%     lkx           - X方向座屈長さ [nme×1]
%     lky           - Y方向座屈長さ（梁は補剛長）[nme×3]
%     ration        - 位置・成分別応力比 [nnm×ncomp×nlc]
%     bkinfo        - 座屈長さ係数の中間値 (struct)
%     id_center_sel - 梁中央位置の選択インデックス [nng×nlc]

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

% 方向別入力の準備
dir_full = zeros(nme, 1);
dir_full(mtype==PRM.GIRDER) = dir_girder;
is_gx = dir_full==PRM.X | dir_full==PRM.XY;
is_gy = dir_full==PRM.Y | dir_full==PRM.XY;
ilc_x = lcdir==PRM.EXP | lcdir==PRM.EXN;
ilc_y = lcdir==PRM.EYP | lcdir==PRM.EYN;

% X方向の座屈長さ係数
[lk_x, kcx, bkinfox] = calc_buckling_length(Iy, mtype, ...
  idm2n1, idm2n2, is_gx, lnm, lm, Em, mejoint(:,[1 2]), ...
  nominal, idmc2nc, options, beta, ilc_x, col_idstory, onfg_x, ...
  column_buckling_K.Kx);

% Y方向の座屈長さ係数
[lk_y, kcy, bkinfoy] = calc_buckling_length(Iy, mtype, ...
  idm2n1, idm2n2, is_gy, lnm, lm, Em, mejoint(:,[3 4]), ...
  nominal, idmc2nc, options, beta, ilc_y, col_idstory, onfg_y, ...
  column_buckling_K.Ky);

% 座屈長さの組み立て
lkx = lk_x;
lky = zeros(nme, 3);
lky(:,1) = lk_y;
lky(mtype==PRM.GIRDER,:) = lb(mtype==PRM.GIRDER,1:3);

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
fb = calc_fb(mewfs, C, clam, ft, mtype, stype, lb(:,1:3), options);

% 移し替え
ftn = ft(idnm2m(:,1),:);
fcn = fc(idnm2m(:,1),:,:);
fbn = fb(idnm2m(:,1),:,:);
fsn = fs(idnm2m(:,1),:);

% 名目梁のfb/fcを4位置から算定し3位置に集約
iggg = find(nmtype==PRM.GIRDER);
img1 = idnm2m(iggg, 1);
fbn4 = calc_nominal_fb(msdim(img1, :), Cn, clam(img1), ...
  ft(img1, :), stype(img1), nomgc.lb, options);
fcn4 = calc_nominal_fc(A(img1), Iy(img1), Iz(img1), ...
  clam(img1), Fm(img1), lkx(img1), nomgc.lb);
nlc_ = size(fbn4, 3);
nng_ = length(iggg);
id_center_sel = 3*ones(nng_, nlc_);
tol_ratio = 1e-4;
for ilc = 1:nlc_
  fb4_ = fbn4(:, :, ilc);
  fc4_ = fcn4(:, :, ilc);
  fbn(iggg, 1, ilc) = fb4_(:, 1);
  fbn(iggg, 2, ilc) = fb4_(:, 2);
  fcn(iggg, 1, ilc) = fc4_(:, 1);
  fcn(iggg, 2, ilc) = fc4_(:, 2);

  % 中央: 検定比で列3/列4を選択（ベクトル化）
  Mc_vec = abs(stcn(iggg, ilc));
  Nc_vec = abs(stn(iggg, 1, ilc));
  r3 = Mc_vec./fb4_(:,3) + Nc_vec./fc4_(:,3);
  r4 = Mc_vec./fb4_(:,4) + Nc_vec./fc4_(:,4);
  sel = 3*ones(nng_, 1);
  sel(abs(r3 - r4) >= tol_ratio & r3 < r4) = 4;
  id_center_sel(:, ilc) = sel;
  idx_ = sub2ind(size(fb4_), (1:nng_)', sel);
  fbn(iggg, 3, ilc) = fb4_(idx_);
  fcn(iggg, 3, ilc) = fc4_(idx_);
end

% 許容応力度比の算定
[ration, fcn, fbn] = calc_nominal_allowable_stress_ratio(...
  stn, stcn, ftn, fcn, fbn, fsn, nmtype, nomgc.Ncn, A);

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
