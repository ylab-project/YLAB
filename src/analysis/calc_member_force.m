function [rs, Mc, rvec] = calc_member_force(ilcset, ...
  dvec, rs, ~, sks, M0, ar, A, Asy, Asz, Iy, Iz, JJ, ...
  Em, Gm, lm, lrxm, lrym, flag, member_property, node, ...
  ~, cbstiff, ~, idm2scb, joint, br_stif, hstiff_type)
%calc_member_force - 部材応力の計算
%
%   [rs, Mc, rvec] = calc_member_force( ...
%     ilcset, dvec, rs, ~, sks, M0, ar, ...
%     A, Asy, Asz, Iy, Iz, JJ, Em, Gm, lm, ...
%     lrxm, lrym, flag, member_property, ...
%     node, ~, cbstiff, ~, idm2scb, ...
%     joint, br_stif, hstiff_type) は、
%   各部材の変位から部材端応力を計算する。
%   通常部材は梁要素剛性行列、ブレースはトラス変換で処理する。
%
%   入力引数:
%     ilcset - 荷重ケース番号 [1×nlc]
%     dvec   - 変位ベクトル [ndf×nlc]
%     rs     - 応力配列 [nme×12×nlc]（空可、内部で初期化）
%     ~      - （未使用、旧frvec）
%     sks    - 全体剛性行列格納配列 [ns6×帯幅]
%     M0     - 固定端モーメント [nme×nlc]
%     ar     - 固定端力 [nme×12×nlc]
%     A      - 断面積 [nme×1]
%     Asy    - せん断断面積Y [nme×1]
%     Asz    - せん断断面積Z [nme×1]
%     Iy     - 断面二次モーメントY [nme×1]
%     Iz     - 断面二次モーメントZ [nme×1]
%     JJ     - ねじり定数 [nme×1]
%     Em     - ヤング係数 [nme×1]
%     Gm     - せん断弾性係数 [nme×1]
%     lm     - 部材長 [nme×1]
%     lrxm   - 剛域長X [nme×2]
%     lrym   - 剛域長Y [nme×2]
%     flag   - 剛性行列計算フラグ
%     member_property - 部材プロパティ構造体
%     node     - 節点構造体
%     ~        - （未使用、旧material）
%     cbstiff  - 複合梁剛性配列
%     ~        - （未使用、旧idm2mat）
%     idm2scb  - 部材→複合梁マッピング [nme×1]
%     joint    - 接合条件 [nme×4]
%     br_stif  - ブレース剛性構造体配列（空可）
%     hstiff_type - 梁水平面内変形の考慮（PRM.GIRDER_HSTIFF_*）
%
%   出力引数:
%     rs   - 部材端応力 [nme×12×nlc]
%     Mc   - 反曲点モーメント [nme×nlc]
%     rvec - 復元力ベクトル [ns6×nlc]
%
%   備考:
%     - 応力側は剛性側（stif_sys_matrix）と異なり微小化せず完全 0 を
%       許容する（ZERO で梁 Iz=0、factor_J(im)=0 で J=0）。
%     - factor_J は member_property.factor_J から取得。

% 共通配列
idme2j1 = member_property.idnode1;
idme2j2 = member_property.idnode2;
cxl = member_property.cxl;
cyl = member_property.cyl;
xr = node.xr;
yr = node.yr;
idnode2jf = node.dof;
mtype = member_property.type;

% 共通定数
nme = size(member_property,1);
ns6 = size(sks,1);
nlc = length(ilcset);

% ブレース除外対象の構築
if ~isempty(br_stif)
  br_im = [br_stif(:).im];
  targetset = setdiff(1:nme, br_im);
else
  targetset = 1:nme;
end

% 計算準備
xr_ = [xr(idme2j1) xr(idme2j2)];
yr_ = [yr(idme2j1) yr(idme2j2)];
czl = cross(cxl, cyl, 2);
rvec = zeros(ns6, nlc);
Mc = zeros(nme, nlc);
if isempty(rs)
  rs = zeros(nme, 12, nlc);
end

% 剛床・剛域・固定端力の前処理
kcb = inf(nme, 1);
valid_cbstiff = (idm2scb > 0) & isfinite(idm2scb);
kcb(valid_cbstiff) = cbstiff(idm2scb(valid_cbstiff));

ar_mask_all = ones(12, nme);
cols_mask = (mtype == PRM.COLUMN) | (mtype == PRM.BRACE) | ...
  (mtype == PRM.HORIZONTAL_BRACE);
ar_mask_all([1 7], cols_mask) = 0;

ke_cache = cell(nme, 1);
tg_cache = cell(nme, 1);
t_cache = cell(nme, 1);
ndi_cache = cell(nme, 1);

% Iz/Asy/J 係数の事前展開（応力側は微小化せず完全 0 を許容）
% 梁水平面内変形の考慮: ZERO は Iz 寄与 0、ACTUAL は原断面のまま、
% RIGID は剛性側と同じ Iz=Iy×1000・Asy 大値化で整合をとる。柱: 1
Iz_fac = ones(nme, 1);
Asy_fac = ones(nme, 1);
isg = mtype == PRM.GIRDER;
switch hstiff_type
  case PRM.GIRDER_HSTIFF_ZERO
    Iz_fac(isg) = 0;
  case PRM.GIRDER_HSTIFF_ACTUAL
    % 原断面の剛性（係数1のまま）
  case PRM.GIRDER_HSTIFF_RIGID
    Iz_fac(isg) = 1000*Iy(isg)./max(Iz(isg), eps);
    Asy_fac(isg) = 1e6;
  otherwise
    error('梁水平面内変形の考慮の指定が不正です: %g', hstiff_type);
end
J_fac = member_property.factor_J;

for im = targetset(:)'
  lrxi = lrxm(im, :);
  lryi = lrym(im, :);
  li = lm(im);
  t_local = [cxl(im, :); cyl(im, :); czl(im, :)];
  Ai = A(im); Asyi = Asy(im) * Asy_fac(im); Aszi = Asz(im);
  Iyi = Iy(im);
  Izi = Iz(im) * Iz_fac(im);
  Ji = JJ(im) * J_fac(im);
  Ei = Em(im); Gi = Gm(im);
  jointi = joint(im, :);

  kcbi = [];
  if isfinite(kcb(im))
    kcbi = kcb(im);
  end

  ke = stif_beam_matrix(li, Ai, Asyi, Aszi, Iyi, Izi, Ji, Ei, Gi, ...
    lrxi, lryi, jointi, kcbi, flag);

  if any([lrxi lryi] > 0)
    tr = eye(12);
    tr(3,5) = -lrxi(1);
    tr(9,11) = lrxi(2);
    tr(2,6) =  lryi(1);
    tr(8,12) = -lryi(2);
    ke = tr' * ke * tr;
  end

  tg = eye(12);
  tg(1,6) = -yr_(im,1);
  tg(2,6) =  xr_(im,1);
  tg(7,12) = -yr_(im,2);
  tg(8,12) =  xr_(im,2);

  ke_cache{im} = ke;
  tg_cache{im} = tg;
  t_cache{im} = t_local;
  ndi_cache{im} = [idnode2jf(idme2j1(im), :), idnode2jf(idme2j2(im), :)];
end

% 通常部材の応力計算
for ilc = ilcset(:)'
  for im = targetset(:)'
    ke = ke_cache{im};
    tg = tg_cache{im};
    t = t_cache{im};
    ndi = ndi_cache{im};

    dg = tg * dvec(ndi, ilc);
    dt = zeros(12, 1);
    for mk = 1:4
      rng = (3*(mk-1)+1):(3*mk);
      dt(rng) = t * dg(rng);
    end

    arm = ke * dt;
    ar_loc = ar(im, :, ilc)';
    ar_loc = ar_loc .* ar_mask_all(:, im);
    arm = arm + ar_loc;

    rs(im, :, ilc) = arm;
    Mc(im, ilc) = M0(im, ilc) + (arm(5) - arm(11)) / 2;
  end
end

% 全ブレース: トラス変換行列で軸力を計算
nbr = length(br_stif);
for idx = 1:nbr
  im = br_stif(idx).im;
  tt_ = br_stif(idx).tt;
  kn_ = br_stif(idx).kn;
  ndi_ = br_stif(idx).ndi;
  for ilc = ilcset(:)'
    d_ = tt_ * dvec(ndi_, ilc);
    N = kn_ * (d_(2) - d_(1));
    rs(im, 1, ilc) = -N;
    rs(im, 7, ilc) = N;
    Mc(im, ilc) = M0(im, ilc);
  end
end

return
end

