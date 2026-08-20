function [stress_constraint, stress_result] = ...
  eval_nominal_allowable_stress_ratio(msdim, stn, A, Iy, Iz, ...
  Zyc, C, mtype, stype, isxdir, isydir, wgx, wgy, Em, Fm, ...
  idm2n, lb, lm, lm_bk_x, lm_bk_y, lnm, mejoint, nominal, ...
  isgmirrored, idmg2ng, idmc2nc, options, beta, lcdir, ...
  col_idstory, column_bracing, Cn, nomgc, column_buckling_K)
%eval_nominal_allowable_stress_ratio - 名目部材の許容応力度比を算定する
%
%   [stress_constraint, stress_result] =
%     eval_nominal_allowable_stress_ratio(...) は、方向別の柱座屈長さ、
%   許容応力度比および5種類の応力制約を算定する。第2出力を要求した
%   場合だけ、最終解析と帳票に必要な詳細結果を返す。
%
%   入力引数:
%     msdim       - 部材断面寸法 [nme×ndim]
%     stn         - 名目部材の応力 [nnm×ncomp×nlc]
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
%                   .column.jointは方向別の柱脚・柱頭接合条件
%     isgmirrored - 梁ミラーフラグ [ng×1]
%     idmg2ng     - 梁→名目梁番号 [ng×1]
%     idmc2nc     - 柱→名目柱番号 [nmc×2]
%     options     - 計算オプション (struct)
%     beta        - ブレース水平力分担率 [nst×nlc]
%     lcdir       - 荷重ケース方向 [nlc×1]
%     col_idstory - 柱の層番号 [nmc×1]
%     column_bracing - 柱の方向別補剛点トポロジー (struct)
%                   .x, .y [nnmc×(maxseg-1) logical]
%     Cn          - 名目梁中央係数 (struct)
%     nomgc       - 名目梁中央データ (struct)
%     column_buckling_K - 柱座屈長さ係数の直接入力値 (struct)
%                         .Kx, .Ky [nmec×1]（NaN=自動計算）
%
%   出力引数:
%     stress_constraint - 応力制約の集約値 (struct)
%       .gr, .gs - 梁曲げ・せん断応力制約
%       .cr, .cs - 柱曲げ・せん断応力制約
%       .bn      - ブレース応力制約
%     stress_result - 最終解析・帳票用の詳細結果 (struct)
%       .gri～.bnij - 位置・ケース別応力制約
%       .fcn, .fbn, .fsn, .ftn - 許容応力度
%       .fcn_display - 引張置換前の許容圧縮応力度（fcL/fcS表示用）
%       .column_fc_applicable - fcL/fcSを数値表示できる柱 [nnm×1]
%       .kcx, .kcy, .lkx, .lky - 座屈長さ係数・座屈長さ
%       .lambday, .lambdaz - 細長比
%       .ration - 位置・成分別応力比
%       .bkinfo, .lbc_nominal - 柱座屈の帳票用結果
%       .id_center_sel - 梁中央位置の選択インデックス
%       .girder_axial_mask - S梁軸力考慮マスク
%       .fbn_by_fb1 - fb1式でfbが決定した位置
%       .nomgc - 中央検定の採用応力度を追加した名目梁中央データ

% 共通配列
nme = length(mtype);
nng = size(nominal.girder.idmeg, 1);
nnc = size(nominal.column.idmec, 1);
nmtype = nominal.property.mtype;
idnm2m = nominal.property.idme;
need_result = nargout == 2;
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
column_joint_x = nominal.column.joint(:, [1, 2]);
column_joint_y = nominal.column.joint(:, [3, 4]);

% 方向別の座屈長さを算定（完全結果時のみ第2出力の詳細を受け取る）
bkx_out = cell(1, 1+need_result);
[bkx_out{:}] = calc_column_buckling_length(Iy, mtype, idm2n1, ...
  idm2n2, isxdir, wgx, lg_bk_end, lnm, lm, lm_bk_x, Em, ...
  mejoint(:, [1, 2]), column_joint_x, nominal, idmc2nc, options, ...
  beta, ilc_x, col_idstory, column_bracing.x, column_buckling_K.Kx);
bky_out = cell(1, 1+need_result);
[bky_out{:}] = calc_column_buckling_length(Iy, mtype, idm2n1, ...
  idm2n2, isydir, wgy, lg_bk_end, lnm, lm, lm_bk_y, Em, ...
  mejoint(:, [3, 4]), column_joint_y, nominal, idmc2nc, options, ...
  beta, ilc_y, col_idstory, column_bracing.y, column_buckling_K.Ky);
lkc_x = bkx_out{1};
lkc_y = bky_out{1};
if need_result
  buckling_x = bkx_out{2};
  buckling_y = bky_out{2};
end

% 座屈長さの組み立て（柱は算定結果、柱以外は座屈用部材長）
is_column = mtype==PRM.COLUMN;
lkx = lm_bk_x(:);
lkx(is_column) = lkc_x;
lky = zeros(nme, 3);
lky(:,1) = lm_bk_y(:);
lky(is_column,1) = lkc_y;
lky(mtype==PRM.GIRDER,:) = lb(mtype==PRM.GIRDER,1:3);

% 細長比と許容圧縮応力度の算定
[lambday, lambdaz] = calc_lambda(A, Iy, Iz, mtype, stype, lkx, lky);
fc = calc_fc(lambday, lambdaz, clam, Fm);

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
% 強軸側は4位置の鉛直補剛区間、弱軸側は水平補剛区間を用いる
fcn4 = calc_nominal_fc(A(img1), Iy(img1), Iz(img1), ...
  clam(img1), Fm(img1), nomgc.lb_vertical, nomgc.lb);
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
    clam(imc_), Fm(imc_), nomgc.lb_vertical, nomgc.lb);
  jcol = j + 2;
  fbn4(:, jcol, :) = fbn4_c(:, jcol, :);
  fbn4_by_fb1(:, jcol, :) = fb1_c(:, jcol, :);
  fcn4(:, jcol, :) = fcn4_c(:, jcol, :);
end
nlc_ = size(fbn4, 3);
girder_axial_mask = build_girder_axial_mask(stn, nomgc.Ncn, ...
  An, nmtype, options);
axial_on = options.s_girder_axial_design ~= PRM.S_GIRDER_AXIAL_NONE;
% 端部軸力の引張判定（引張正）。検定のfc・fb→ft置換と、
% S柱断面算定表のfcL/fcS表示条件で同じ判定を用いる。
axial_tension = stn(:, [1 7], :) .* An >= PRM.TOL_FORCE_N;
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
  ft_center = ftn(iggg, ilc_ft);
  % 引張はfb・fcともftで検定する
  use_ft = use_axial_c & (N_center >= PRM.TOL_FORCE_N);
  fb_eval(use_ft, :) = repmat(ft_center(use_ft), 1, 2);
  % 圧縮検定が働かない中央（引張または閾値未満のN）は、SS7と
  % 同じくfcにftを採用する（UN13_14のRG1中央はN=0でfc=156.7）
  no_comp = axial_on & ~(use_axial_c & (N_center <= -PRM.TOL_FORCE_N));
  fc_eval(no_comp, :) = repmat(ft_center(no_comp), 1, 2);
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

% 表示用許容圧縮応力度（引張置換前）。SS7は引張時の検定にft
% （計算編 式6.18）、fcL/fcS欄の表示にfcを使う（出力編7.3.11）。
fcn_display = fcn;

% fcL/fcS欄の表示可否。全断面算定ケースの両端が引張となる柱では、
% SS7実出力に合わせて数値を表示しない。
is_all_tension = all(all(axial_tension, 3), 2);
column_fc_applicable = ~(nmtype == PRM.COLUMN & is_all_tension);

% 許容応力度比の算定。fcn/fbn は検定用の確定値（引張置換後）とする。
[ration, fcn, fbn] = calc_nominal_allowable_stress_ratio(stn, ftn, ...
  fcn, fbn, fsn, nmtype, nomgc.Ncn, An, girder_axial_mask, ...
  axial_tension);
for ilc = 1:nlc_
  ration(iggg, 13, ilc) = nomgc.ratioM(iggg, ilc);
  ration(iggg, 14, ilc) = nomgc.ratioN(iggg, ilc);
end

% TB応力比の上書き（N/Ta）
ration = calc_nominal_allowable_stress_ratio_tension_brace(...
  ration, stn, nominal, stype, A, msdim);

% 位置・ケース別の制約値
[gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij] = ...
  calc_nominal_stress_constraints(ration, nominal, girder_axial_mask);

% ミラー配置後に候補評価用の5制約群へ集約
ngsub = nominal.girder.idsub(:,2);
[gri, grj, gsi, gsj] = mirror_arrangement(isgmirrored, ...
  idmg2ng, ngsub, gri, grj, gsi, gsj);
stress_constraint.gr = max(reshape([gri; grj; grc], nng, []), [], 2);
stress_constraint.gs = max(reshape([gsi; gsj], nng, []), [], 2);
stress_constraint.cr = max(reshape([cri; crj], nnc, []), [], 2);
stress_constraint.cs = max(reshape([csi; csj], nnc, []), [], 2);
stress_constraint.bn = max(bnij, [], 2);

if ~need_result
  return
end

% 位置・ケース別制約
stress_result.gri = gri;
stress_result.grj = grj;
stress_result.grc = grc;
stress_result.cri = cri;
stress_result.crj = crj;
stress_result.gsi = gsi;
stress_result.gsj = gsj;
stress_result.csi = csi;
stress_result.csj = csj;
stress_result.bnij = bnij;

% 許容応力度と座屈長さ
stress_result.fcn = fcn;
stress_result.fcn_display = fcn_display;
stress_result.column_fc_applicable = column_fc_applicable;
stress_result.fbn = fbn;
stress_result.fsn = fsn;
stress_result.ftn = ftn;
stress_result.kcx = buckling_x.kc;
stress_result.kcy = buckling_y.kc;
stress_result.lkx = lkx;
stress_result.lky = lky;
stress_result.lambday = lambday;
stress_result.lambdaz = lambdaz;
stress_result.ration = ration;

% 柱座屈長さ係数の帳票用中間値
bkinfo.IcLc = buckling_x.IcLc;
bkinfo.sumIcTop = buckling_x.sumIcTop;
bkinfo.sumIcBot = buckling_x.sumIcBot;
bkinfo.sumIgTopX = buckling_x.sumIgTop;
bkinfo.sumIgBotX = buckling_x.sumIgBot;
bkinfo.sumIgTopY = buckling_y.sumIgTop;
bkinfo.sumIgBotY = buckling_y.sumIgBot;
bkinfo.GAx = buckling_x.GA;
bkinfo.GBx = buckling_x.GB;
bkinfo.GAy = buckling_y.GA;
bkinfo.GBy = buckling_y.GB;
bkinfo.kcxRaw = buckling_x.kcRaw;
bkinfo.kcyRaw = buckling_y.kcRaw;
bkinfo.kcx = buckling_x.kcNominal;
bkinfo.kcy = buckling_y.kcNominal;
stress_result.bkinfo = bkinfo;

% 柱補剛間隔は座屈係数中間値と分離する
lbc_nominal.x = buckling_x.lbc_nominal;
lbc_nominal.y = buckling_y.lbc_nominal;
lbc_nominal.bk.x = buckling_x.lbc_nominal_bk;
lbc_nominal.bk.y = buckling_y.lbc_nominal_bk;
stress_result.lbc_nominal = lbc_nominal;

% 梁中央検定と帳票用補助結果
stress_result.id_center_sel = id_center_sel;
stress_result.girder_axial_mask = girder_axial_mask;
stress_result.fbn_by_fb1 = fbn_by_fb1;
stress_result.nomgc = nomgc;

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
