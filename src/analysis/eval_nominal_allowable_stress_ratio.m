function [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij, ...
  fcn, fbn, fsn, ftn, kcx, kcy, lkx, lky, ration, bkinfo, ...
  id_center_sel, girder_axial_mask, fbn_by_fb1, nomgc] = ...
  eval_nominal_allowable_stress_ratio(msdim, stn, stcn, A, Iy, Iz, ...
  Zyc, C, mtype, stype, isxdir, isydir, wgx, wgy, Em, Fm, ...
  idm2n, lb, lm, lm_bk_x, lm_bk_y, lnm, mejoint, nominal, ...
  isgmirrored, idmg2ng, idmc2nc, options, beta, lcdir, ...
  col_idstory, onfg_x, onfg_y, Cn, nomgc, column_buckling_K)
%eval_nominal_allowable_stress_ratio - 名目部材の許容応力度比を算定する
%
%   [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij,
%     fcn, fbn, fsn, ftn, kcx, kcy, lkx, lky, ration,
%     bkinfo, id_center_sel, girder_axial_mask,
%     fbn_by_fb1] = eval_nominal_allowable_stress_ratio(msdim, stn,
%     stcn, A, Iy, Iz, C, mtype, stype, isxdir, isydir, wgx,
%     wgy, Em, Fm, idm2n, lb, lm, lm_bk_x, lm_bk_y, lnm, mejoint,
%     nominal, isgmirrored, idmg2ng, idmc2nc, options,
%     beta, lcdir, col_idstory, onfg_x, onfg_y, Cn,
%     nomgc, column_buckling_K) は、
%   方向別に calc_buckling_length を2回呼び出して柱座屈長さ
%   係数を算定し、許容応力度および各端部の許容応力度比を返す。
%
%   入力引数:
%     msdim       - 部材断面寸法 [nme×ndim]
%     stn         - 名目部材の応力 [nnm×ncomp×nlc]
%     stcn        - 名目梁中央モーメント [nng×nlc]
%     A           - 断面積 [nme×1]
%     Iy, Iz      - 断面2次モーメント [nme×1]
%     Zyc         - 中央曲げ応力度用断面係数 [nme×1]
%     C           - ねじり定数等 (struct)
%     mtype       - 部材タイプ [nme×1]
%     stype       - 断面タイプ [nme×1]
%     isxdir       - X方向計算に寄与する梁部材 [nme×1]
%     isydir       - Y方向計算に寄与する梁部材 [nme×1]
%     wgx, wgy    - 梁剛比のX/Y方向平面振れ角重み cos2θ [nme×1]
%                   （SS7互換: 水平面内の振れ角のみ考慮）
%     Em          - ヤング係数 [nme×1]
%     Fm          - 基準強度 [nme×1]
%     idm2n       - 部材→節点番号 [nme×2]
%     lb          - 補剛間隔配列 [nme×3]
%     lm          - 芯間距離（構造心間、控除前、Lb 表示用）[nme×1]
%     lm_bk_x     - X方向芯間距離（端部控除後、Lk 算定用）[nme×1]
%     lm_bk_y     - Y方向芯間距離（端部控除後、Lk 算定用）[nme×1]
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
%                     .lbc_nominal.x / .y       : 控除前テーブル
%                     .lbc_nominal.bk.x / .bk.y : 控除後テーブル
%     id_center_sel - 梁中央位置の選択インデックス [nng×nlc]
%     girder_axial_mask - S梁軸力考慮マスク (struct)
%     fbn_by_fb1 - fb1式でfbが決定した位置 [nnm×npos×nlc]
%     nomgc - 中央検定の採用応力度を追加した名目梁中央データ

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

% 方向別入力の準備（isxdir/isydir は呼び出し側で算定済み）
ilc_x = lcdir==PRM.EXP | lcdir==PRM.EXN;
ilc_y = lcdir==PRM.EYP | lcdir==PRM.EYN;
lg_bk_end = calc_buckling_girder_end_length(lnm, lm, mtype, ...
  idm2n1, idm2n2, nominal.girder);

% X方向の座屈長さ係数
[lk_x, kcx, bkinfox] = calc_buckling_length(Iy, mtype, idm2n1, ...
  idm2n2, isxdir, wgx, lg_bk_end, lnm, lm, lm_bk_x, Em, ...
  mejoint(:,[1 2]), nominal, idmc2nc, options, beta, ilc_x, ...
  col_idstory, onfg_x, column_buckling_K.Kx);

% Y方向の座屈長さ係数
[lk_y, kcy, bkinfoy] = calc_buckling_length(Iy, mtype, idm2n1, ...
  idm2n2, isydir, wgy, lg_bk_end, lnm, lm, lm_bk_y, Em, ...
  mejoint(:,[3 4]), nominal, idmc2nc, options, beta, ilc_y, ...
  col_idstory, onfg_y, column_buckling_K.Ky);

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
bkinfo.lbc_nominal.x = bkinfox.lbc_nominal;
bkinfo.lbc_nominal.y = bkinfoy.lbc_nominal;
bkinfo.lbc_nominal.bk.x = bkinfox.lbc_nominal_bk;
bkinfo.lbc_nominal.bk.y = bkinfoy.lbc_nominal_bk;

% 許容圧縮応力度の算定
fc = calc_fc(A, Iy, Iz, clam, mtype, stype, Fm, lkx, lky);

% 曲げ許容応力度の算定
mewfs = msdim(stype==PRM.WFS,:);
fb = calc_fb(mewfs, C, clam, ft, mtype, stype, lb(:,1:3), options);

% 移し替え
An = A(idnm2m(:, 1));
ftn = ft(idnm2m(:,1),:);
fcn = fc(idnm2m(:,1),:,:);
fbn = fb(idnm2m(:,1),:,:);
fbn_by_fb1 = false(size(fbn));
fsn = fs(idnm2m(:,1),:);

% 名目梁のfb/fcを4位置から算定し3位置に集約
iggg = find(nmtype==PRM.GIRDER);
nng_ = length(iggg);
img1 = idnm2m(iggg, 1);
[fbn4, fbn4_by_fb1] = calc_nominal_fb(msdim(img1, :), Cn, ...
  clam(img1), ft(img1, :), stype(img1), nomgc.lb, options);
fcn4 = calc_nominal_fc(A(img1), Iy(img1), Iz(img1), ...
  clam(img1), Fm(img1), lkx(img1), nomgc.lb);
center_sub = nomgc.idsub(:, 3:4);
id_center_m = zeros(nng_, 2);
for j = 1:2
  idx_ = sub2ind(size(idnm2m), iggg(:), center_sub(:, j));
  id_center_m(:, j) = idnm2m(idx_);
end
nomgc.id_center_m = id_center_m;
nomgc.A_center = A(id_center_m);
nomgc.Z_center = Zyc(id_center_m);
for j = 1:2
  imc_ = id_center_m(:, j);
  [fbn4_c, fb1_c] = calc_nominal_fb(msdim(imc_, :), Cn, ...
    clam(imc_), ft(imc_, :), stype(imc_), nomgc.lb, options);
  fcn4_c = calc_nominal_fc(A(imc_), Iy(imc_), Iz(imc_), ...
    clam(imc_), Fm(imc_), lkx(imc_), nomgc.lb);
  jcol = j + 2;
  fbn4(:, jcol, :) = fbn4_c(:, jcol, :);
  fbn4_by_fb1(:, jcol, :) = fb1_c(:, jcol, :);
  fcn4(:, jcol, :) = fcn4_c(:, jcol, :);
end
nlc_ = size(fbn4, 3);
girder_axial_mask = build_girder_axial_mask(stn, nomgc.Ncn, ...
  An, nmtype, options);
id_center_sel = 3*ones(nng_, nlc_);
nomgc.stcN = zeros(size(nomgc.Ncn));
nomgc.stcM = zeros(size(nomgc.Mcn));
nomgc.ratioN = zeros(size(nomgc.Ncn));
nomgc.ratioM = zeros(size(nomgc.Mcn));
nomgc.ratioTotal = zeros(size(nomgc.Mcn));
nomgc.ratioTotalCandidate = zeros(nng_, 2, nlc_);
tol_ratio = 1e-4;
for ilc = 1:nlc_
  ilc_ft = min(ilc, 2);
  fb4_ = fbn4(:, :, ilc);
  fc4_ = fcn4(:, :, ilc);
  fb1_4 = fbn4_by_fb1(:, :, ilc);
  fbn(iggg, 1, ilc) = fb4_(:, 1);
  fbn(iggg, 2, ilc) = fb4_(:, 2);
  fbn_by_fb1(iggg, 1, ilc) = fb1_4(:, 1);
  fbn_by_fb1(iggg, 2, ilc) = fb1_4(:, 2);
  fcn(iggg, 1, ilc) = fc4_(:, 1);
  fcn(iggg, 2, ilc) = fc4_(:, 2);

  % 中央: 候補3/4をSS7帳票用の確定許容応力度で比較する。
  M_center = nomgc.Mcn(iggg, ilc);
  N_center = nomgc.Ncn(iggg, ilc);
  stcM3 = M_center ./ nomgc.Z_center(:, 1);
  stcM4 = M_center ./ nomgc.Z_center(:, 2);
  stcN3 = N_center ./ nomgc.A_center(:, 1);
  stcN4 = N_center ./ nomgc.A_center(:, 2);
  fb_eval = fb4_(:, 3:4);
  fc_eval = fc4_(:, 3:4);
  use_axial_c = girder_axial_mask.c(iggg, ilc);
  use_ft = use_axial_c & (N_center >= PRM.TOL_FORCE_N);
  ft_center = ftn(iggg, ilc_ft);
  fb_eval(use_ft, :) = repmat(ft_center(use_ft), 1, 2);
  fc_eval(use_ft, :) = repmat(ft_center(use_ft), 1, 2);
  r3 = abs(stcM3) ./ fb_eval(:, 1) + abs(stcN3) ./ fc_eval(:, 1);
  r4 = abs(stcM4) ./ fb_eval(:, 2) + abs(stcN4) ./ fc_eval(:, 2);
  sel = 3*ones(nng_, 1);
  sel(abs(r3 - r4) >= tol_ratio & r3 < r4) = 4;
  id_center_sel(:, ilc) = sel;
  idx_ = sub2ind([nng_, 2], (1:nng_)', sel - 2);
  stcM_pair = [stcM3 stcM4];
  stcN_pair = [stcN3 stcN4];
  stcM_sel = stcM_pair(idx_);
  stcN_sel = stcN_pair(idx_);
  fb_sel = fb_eval(idx_);
  fc_sel = fc_eval(idx_);
  fbn(iggg, 3, ilc) = fb_sel;
  fbn_by_fb1(iggg, 3, ilc) = fb1_4(idx_);
  fbn_by_fb1(iggg(use_ft), 3, ilc) = false;
  fcn(iggg, 3, ilc) = fc_sel;
  nomgc.stcM(iggg, ilc) = stcM_sel;
  nomgc.stcN(iggg, ilc) = stcN_sel;
  nomgc.ratioM(iggg, ilc) = stcM_sel ./ fb_sel;
  nomgc.ratioN(iggg, ilc) = stcN_sel ./ fc_sel;
  nomgc.ratioTotal(iggg, ilc) = abs(nomgc.ratioM(iggg, ilc)) ...
    + abs(nomgc.ratioN(iggg, ilc));
  nomgc.ratioTotalCandidate(:, 1, ilc) = r3;
  nomgc.ratioTotalCandidate(:, 2, ilc) = r4;
end

% 許容応力度比の算定。fcn/fbn はSS7帳票・検定用の確定値とする。
[ration, fcn, fbn] = calc_nominal_allowable_stress_ratio( ...
  stn, stcn, ftn, fcn, fbn, fsn, nmtype, nomgc.Ncn, An, ...
  girder_axial_mask);
for ilc = 1:nlc_
  ration(iggg, 13, ilc) = nomgc.ratioM(iggg, ilc);
  ration(iggg, 14, ilc) = nomgc.ratioN(iggg, ilc);
end

% TB応力比の上書き（N/Ta）
ration = calc_nominal_allowable_stress_ratio_tension_brace(...
  ration, stn, nominal, stype, A, msdim);

% 制約値の計算
[gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij] = ...
  calc_nominal_stress_constraints(ration, nominal, girder_axial_mask);

% ミラー配置
ngsub = nominal.girder.idsub(:,2);
[gri, grj, gsi, gsj] = mirror_arrangement(isgmirrored, ...
  idmg2ng, ngsub, gri, grj, gsi, gsj);

return
end

%----------------------------------------------------------
function mask = build_girder_axial_mask(stn, Ncn, An, nmtype, options)
%build_girder_axial_mask - S梁の軸力考慮マスクを作成

nlc = size(stn, 3);
nnm = size(stn, 1);
mask.i = true(nnm, nlc);
mask.c = true(nnm, nlc);
mask.j = true(nnm, nlc);

is_girder = nmtype == PRM.GIRDER;
switch options.s_girder_axial_design
  case PRM.S_GIRDER_AXIAL_NONE
    mask.i(is_girder, :) = false;
    mask.c(is_girder, :) = false;
    mask.j(is_girder, :) = false;
  case PRM.S_GIRDER_AXIAL_ALL
    % 初期値 true のまま使用する。
  case PRM.S_GIRDER_AXIAL_AUTO
    force_i = reshape(stn(:, 1, :), nnm, nlc) .* An;
    force_j = reshape(stn(:, 7, :), nnm, nlc) .* An;
    mask.i(is_girder, :) = abs(force_i(is_girder, :)) >= PRM.TOL_FORCE_N;
    mask.c(is_girder, :) = abs(Ncn(is_girder, :)) >= PRM.TOL_FORCE_N;
    mask.j(is_girder, :) = abs(force_j(is_girder, :)) >= PRM.TOL_FORCE_N;
end

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
