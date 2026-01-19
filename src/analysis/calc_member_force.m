function [rs, Mc, rvec] = calc_member_force(ilcset, dvec, rs, ...
  frvec, sks, M0, ar, A, Asy, Asz, Iy, Iz, JJ, Em, prm, ...
  lm, lrxm, lrym, flag, ...
  member_property, node, material, cbstiff, idm2mat, idm2scb, joint)
%MEMBER_FORCE この関数の概要をここに記述
%   詳細説明をここに記述

% 共通配列
idme2j1 = member_property.idnode1;
idme2j2 = member_property.idnode2;
cxl = member_property.cxl;
cyl = member_property.cyl;
xr = node.xr;
yr = node.yr;
idnode2jf = node.dof;
% E = material.E;
% pr = material.pr;
mtype = member_property.type;

% 共通定数
nme = size(member_property,1);
ns6 = size(sks,1);
nlc = length(ilcset);

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

for im = 1:nme
  lrxi = lrxm(im, :);
  lryi = lrym(im, :);
  li = lm(im);
  t_local = [cxl(im, :); cyl(im, :); czl(im, :)];
  Ai = A(im); Asyi = Asy(im); Aszi = Asz(im);
  Iyi = Iy(im); Ji = JJ(im);
  % 梁の弱軸剛性Izはゼロとする（SS7互換）
  if mtype(im) == PRM.GIRDER
    Izi = 0;
  else
    Izi = Iz(im);
  end
  Ei = Em(im); pri = prm(im);
  jointi = joint(im, :);

  kcbi = [];
  if isfinite(kcb(im))
    kcbi = kcb(im);
  end

  ke = stif_beam_matrix(li, Ai, Asyi, Aszi, Iyi, Izi, Ji, Ei, pri, ...
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

for ilc = ilcset(:)'
  for im = 1:nme
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

return
end

