function [msprop, secdim, dvec, dnode, felement,...
  stn, stcn, Mc, C, vix, viy, ...
  rvec, rs, dfn, rvec0, rs0, Mc0, dfn0, isuplifted, sw, ...
  lf, lr, lm, lnm, lbnm, ...
  Iy0, Iz0, gphiI, cphiI, cbs, baseline, node, story, floor] = ...
  analysis_frame(xvar, com, options)

% 共通定数
nbw = com.nbw;
ndf = com.ndf;
nlc = com.nlc;
nme = com.nme;
% nmec = com.nmec;
% nmeg = com.nmeg;
nnode = com.nnode;
ns6 = com.ns6;
% nstory = com.nstory;
% nsec = com.nsec;
% nsecg = com.nsecg;
% nseccb = com.nseccb;
nsup = com.nsup;
nsechb = com.nsechb;

% ID変換
idm2mg = com.member.property.idmeg;
idm2n1 = com.member.property.idnode1;
idm2n2 = com.member.property.idnode2;
idm2n = [idm2n1 idm2n2];
idm2s = com.member.property.idsec;
idm2scb= com.member.property.idseccb;
idmc2m = com.member.column.idme;
idmg2m = com.member.girder.idme;
idn2df = com.node.dof;
idn2st = com.node.idstory;
idf2n = com.idf2node;
idsc2s = com.section.column.idsec;
idsup2n = com.support.idnode;
idst2nrep = com.story.idnoderep;
idnm2m = com.nominal.property.idme;

% フラグ
isfixedsup = com.support.isfixed;
isrigidstory = com.story.isrigid;

% 共通配列
ar = com.ar;
baseline = com.baseline;
cbstiff = com.section.column_base.property;
column_base = com.section.column_base;
column_base_list = com.column_base_list;
nominal_girder = com.nominal.girder;
nominal_column = com.nominal.column;
nominal_property = com.nominal.property;
M0 = com.M0;
% comp_effect = com.member.girder.comp_effect;
% cxl = com.member.property.cxl;
% cyl = com.member.property.cyl;
matE = com.material.E;
matF = com.material.F;
matpr = com.material.pr;
matisSN = com.material.isSN;
floor = com.floor;
% fvec = com.feqvec;
jdof = com.node.dof;
% Lb = com.member.girder.Lb;
is_through_girder = com.member.girder.isthrough;
lbng = com.member.girder.stiffening_lb;
lxcg = com.member.girder.stiffening_xc;
% lm = com.member.property.lm;
% lgm_through = com.member.girder.lm_through;
lcdir = com.loadcase.dir;
material = com.material;
section = com.section;
member = com.member;
member_column = com.member.column;
% member_column = table2struct(com.member.column,"ToScalar",true);
member_girder = table2struct(com.member.girder,"ToScalar",true);
% member_brace = table2struct(com.member.brace,"ToScalar",true);
member_property = com.member.property;
mtype = com.member.property.type;
% mstype = com.member.property.section_type;
% mgstype = com.member.girder.section_type;
node = com.node;
% nstiff = com.member.girder.nstiff;
scallop = com.girder_scallop_size;
secmgr = com.secmgr;
slab.width = com.member.girder.slab_width;
slab.thickness = com.member.girder.slab_thickness;
story = com.story;
stype = com.section.property.type;
% stress_factor = com.sectionList.design_stress_factor(idmc2slist);
xr = com.node.xr;
yr = com.node.yr;
fnode = com.fnode;
faddnode = com.faddnode;
felement = com.felement;

% ---
if (options.discretization)
  secdim = secmgr.findNearestSection(xvar, options);
  ids2slist = SectionManager.getSectionListMapping(secdim);
else
  % TODO:要見直し
  % mewfs = [Ho(Hn) Bo(Bn) two(twn) tfo(tfn) zeros(length(tfn),1)];
  % mehss = [Do(Dn) to(tn) zeros(length(tn),1)];
end
sprop = calc_secprop(secdim, stype, scallop, secmgr);
sprop.F = secmgr.extractSectionMaterialF(secdim, matF);
msprop = sprop(idm2s,:);
msdim = secdim(idm2s,:);
A = msprop.A;
Asy = msprop.Asy;
Asz = msprop.Asz;
Aw = msprop.Aw;
Af = msprop.Af;
Iy = msprop.Iy;
Iz = msprop.Iz;

% 材料定数
idm2mat = secmgr.getIdMemberToMaterial(ids2slist);

% ヤング係数設定
Em = zeros(nme,1);
for im = 1:nme
  if idm2mat(im) > 0 && idm2mat(im) <= length(matE)
    Em(im) = matE(idm2mat(im));
  elseif idm2mat(im) > 0
    error('analysis_frame:MaterialIDOutOfRange', ...
      '部材%dの材料ID(%d)が材料データの範囲外です', ...
      im, idm2mat(im));
  end
end

Fm = msprop.F;
prm = zeros(nme,1); prm(idm2mat>0) = matpr(idm2mat(idm2mat>0));
isSNm = zeros(nme,1); isSNm(idm2mat>0) = matisSN(idm2mat(idm2mat>0));

% 水平ブレース
for isechb = 1:nsechb
  isec = section.horizontal_brace.idsec(isechb);
  Em(idm2s==isec) = section.horizontal_brace.E(isechb);
end

% 結果の保存
msprop.E = Em;
% msprop.F = Fm;  % 既に108行目で設定済み
msprop.pr = prm;
msprop.isSN = isSNm;

% 構造体への変換
msprop = table2struct(msprop,"ToScalar",true);

% 設計応力割増
sec_stress_factor = secmgr.getSectionStressFactor(ids2slist);
stress_factor = sec_stress_factor(idm2s);

% 床による梁剛性の考慮（合成梁）
[Igm, gphiI] = calc_composite_girder_Iy(...
  member_girder, msdim, msprop, idmg2m, options);
Iy(idmg2m) = Igm;

% 柱の剛度増減率
cphiI = member_column.phiI;
Iy(mtype==PRM.COLUMN) = Iy(mtype==PRM.COLUMN).*cphiI(:,1);
Iz(mtype==PRM.COLUMN) = Iz(mtype==PRM.COLUMN).*cphiI(:,2);

% その他
Zy = msprop.Zy;
Zz = msprop.Zz;
Zyf = msprop.Zyf;
Zys = msprop.Zys;
JJ = msprop.JJ;

% 柱脚剛性の計算
Dcb = secdim(idsc2s(column_base.idsecc),1);
cbs = calc_column_base_section(...
  Dcb, cbstiff, column_base, column_base_list);
cbstiff = cbs.stiff;

% 形状の更新
[~, zcoord, nodez, cxl, cyl, lm, lf, lr, story, floor] = ...
  update_geometry(...
  secdim, baseline, node, story, floor, section, member, cbs, options);
member_property.cxl = cxl;
member_property.cyl = cyl;
baseline.z.coord = zcoord;
node.z = nodez;
lrxm = zeros(nme,2);
lrxm(mtype==PRM.COLUMN,:) = lr.columnx;
lrxm(mtype==PRM.GIRDER,:) = lr.girder;
lrym = zeros(nme,2);
lrym(mtype==PRM.COLUMN,:) = lr.columny;

% 分割部材の剛域・断面性能修正
isrigid_xm = sum(lrxm,2)>=lm;
isrigid_ym = sum(lrym,2)>=lm;
lrxm(isrigid_xm,1) = 0;
lrxm(isrigid_xm,2) = 0;
lrym(isrigid_ym,1) = 0;
lrym(isrigid_ym,2) = 0;
Iy0 = Iy; Iz0 = Iz;
Iy(isrigid_xm) = Iy(isrigid_xm)*PRM.RIGID_SCALE;
Iz(isrigid_ym) = Iz(isrigid_ym)*PRM.RIGID_SCALE;

% 1本部材
lnm = lm;

% 通し梁長さ
lnm(mtype==PRM.GIRDER) = ...
  calc_nominal_girder_length(nominal_girder, lm(mtype==PRM.GIRDER));

% 通し柱長さ
lnm(mtype==PRM.COLUMN) = ...
  calc_nominal_column_length(nominal_column, lm(mtype==PRM.COLUMN));

% 横補剛間隔の更新
lbng = update_lb_nominal_girder(lm(mtype==PRM.GIRDER), lbng);
lbnc = update_lb_nominal_column(lm(mtype==PRM.COLUMN), ...
  lnm(mtype==PRM.COLUMN), nominal_column);
lbnm = zeros(nme,3);
lbnm(mtype==PRM.GIRDER,1:3) = lbng;
lbnm(mtype==PRM.COLUMN,1:3) = lbnc;

% 等価外力（要素荷重）の更新
felement = update_felement(felement, ar, cxl, cyl, idn2df, idm2n);
fvec = fnode+faddnode-felement;

% 自重の計算
% if options.consider_self_weight || options.consider_finishing_material
if options.consider_self_weight && options.consider_finishing_material
  sw = comp_self_weight(A, lm, member_property, msdim, slab, idn2df, options);
  fvec(:,1) = fvec(:,1)-sw.f;
  ar(:,:,1) = ar(:,:,1)+sw.ar;
  M0(:,1)= M0(:,1)+sw.M0;
else
  sw.ar = zeros(nme,12);
  sw.f = zeros(ndf,1);
  sw.fc = zeros(ndf,1);
  sw.fg = zeros(ndf,1);
  sw.M0 = zeros(nme,1);
end

% 計算条件
flag = struct("consider_shear_deformation", ...
  options.consider_shear_deformation);

% 柱梁端部の結合条件
% mejoint: 1:X柱脚, 2:X柱頭, 3:Y柱脚, 4:Y柱頭
gjoint = member_girder.joint;
cjoint = member_column.joint;
mejoint = PRM.FIX*ones(nme,4);
mejoint(idmg2m,:) = gjoint;
mejoint(idmc2m,:) = cjoint;

% ピン節点の外力解除
[fvec, ar] = modify_force_for_pinjoint(fvec, ar, mejoint);

% 剛性行列の作成
ksmat0 = stif_sys_matrix(A, Asy, Asz, Iy, Iz, JJ, ...
  cxl, cyl, lm, Em, prm, xr, yr, lrxm, lrym, cbstiff, mtype, ...
  idn2df, idf2n, idm2n1, idm2n2, idm2scb, mejoint, ...
  ndf, nbw, flag);

if options.consider_foundation_uplift
  iter_max = 30;
else
  iter_max = 1;
end

% 初期化
isuplifted = false(nsup, nlc);
dvec = zeros(ndf, nlc);
dnode = zeros(nnode,6,nlc);
sks = zeros(ns6, nlc);
% rs = zeros(nme, 12, nlc);
frvec = zeros(ndf, nlc);
rvec = zeros(ns6, nlc);

% 解析ループ
for iter = 1:iter_max
  if ~options.consider_foundation_uplift
    % 浮き上がりを考慮しない場合は一括で解く
    ilcset = 1:nlc;
    isuplifted = false(nsup, 1);
    [ksmat, sks] = add_sup_stif(...
      ksmat0, xr, yr, idsup2n, isfixedsup, isuplifted, idn2df);
    % [ks, sks] = suptsf(ks0, idsup2n, issupfixed, isuplifted, idn2df);
    dvec = eqsoln(ksmat, fvec, nbw, ndf);
    sks = repmat(sks, 1, nlc);
    dnode = trans_dvec2dnode(ilcset, dnode, dvec);
    rvec = reaction_force(ilcset, dnode, frvec, rvec, sks, ...
      xr, yr, idn2df, idsup2n, isfixedsup);
    break
  end

  if iter==1
    % 長期荷重時の変位・反力計算
    ilc = 1;
    [ksmat, sks(:,ilc)] = add_sup_stif(...
      ksmat0, xr, yr, idsup2n, isfixedsup, isuplifted(:,ilc), idn2df);
    dvec(:,ilc) = eqsoln(ksmat, fvec(:,ilc), nbw, ndf);
    dnode = trans_dvec2dnode(ilc, dnode, dvec);
    rvec = reaction_force(ilc, dnode, frvec, rvec, sks, ...
      xr, yr, idn2df, idsup2n, isfixedsup);
  end

  % 長期反力を外力に変換
  frvec = uplift_force(idn2df, idm2n1, idsup2n, isfixedsup, ...
    rvec, fvec, isuplifted);

  % 地震荷重時の変位計算
  for ilc = 2:nlc
    [ksmat, sks(:,ilc)] = add_sup_stif(...
      ksmat0, xr, yr, idsup2n, isfixedsup, isuplifted(:,ilc), idn2df);
    dvec(:,ilc) = eqsoln(ksmat, frvec(:,ilc), nbw, ndf);
  end

  % 浮き上がり判定
  isuplifted_previous = isuplifted;
  isuplifted = check_uplift(idn2df, idsup2n, isfixedsup, dvec);
  % sum(+(isuplifted~=isuplifted_previous));

  % 収束判定
  if all(all(isuplifted==isuplifted_previous))
    break
  end
end

% 反力計算
ilcset = 2:nlc;
dnode = trans_dvec2dnode(ilcset, dnode, dvec);
rvec = reaction_force(ilcset, dnode, frvec, rvec, sks, ...
  xr, yr, idn2df, idsup2n, isfixedsup);

% 応力計算
[rs, Mc] = calc_member_force(1:nlc, dvec, [], ...
  frvec, sks, M0, ar, A, Asy, Asz, Iy, Iz, JJ, Em, prm, ...
  lm, lrxm, lrym, flag, ...
  member_property, node, material, cbstiff, idm2mat, idm2scb, mejoint);
rs0 = rs; Mc0 = Mc; rvec0 = rvec;

% % 荷重ケースの重ね合わせ
[rs, Mc, rvec, cgsrn] = superpose_analysis_case(...
  rs0, Mc0, rvec0, lcdir, idmc2m, idmg2m, lm, lf, stress_factor);

% 設計応力の計算
dfm0 = calc_face_moment(rs0, lcdir, idmc2m, idmg2m, lm, lf, nominal_column);
dfn0 = calc_design_force(...
  dfm0, Mc0, rvec0, lcdir, idmc2m, idmg2m, lnm, lf, nominal_property);
dfn = superpose_design_force(dfn0, lcdir);

% 許容応力度計算用の係数算定
C = calc_modified_C(...
  rs, Mc, M0, lm, lbng, lxcg, idm2mg, is_through_girder);

% 柱梁耐力比算定用の軸力による全塑性曲げモーメント低下率の算定
[vix, viy] = reduction_rate(mtype, cgsrn, A, Fm, lcdir);

% 応力度計算
if options.consider_web_at_girder_center
  Zyc = Zy;
else
  Zyc = Zyf;
end
% 材端部の断面係数（WFSのみにZys/Zyfを適用）
mstype = stype(idm2s);
Zyij = Zy;  % デフォルトはZy（非ゼロ）
if options.consider_web_at_girder_end
  Zyij(mstype==PRM.WFS) = Zys(mstype==PRM.WFS);
else
  Zyij(mstype==PRM.WFS) = Zyf(mstype==PRM.WFS);
end
% An = Aw+Af;
% [st, stc] = stress(rs, Mc, A, Asy, Asz, Aw, Zy, Zz, Zyij, Zyc, mtype);
[stn, stcn] = calc_nominal_stress(...
  dfn, Mc, A, Asy, Asz, Aw, Zy, Zz, Zyij, Zyc, mtype, idnm2m);
% -------------------------------------------------------------------------
  function dnode = trans_dvec2dnode(ilcset, dnode, dvec)
    % 剛床を考慮した節点変位への変換
    for in_=1:nnode
      for ilc_=ilcset
        dnode(in_,:,ilc_) = dvec(jdof(in_,:),ilc_);
        is_ = idn2st(in_);
        if isrigidstory(is_)
          idnr = idst2nrep(is_);
          rz = dnode(idnr,6,ilc_);
          dnode(in_,1,ilc_) = dnode(in_,1,ilc_)-yr(in_)*rz;
          dnode(in_,2,ilc_) = dnode(in_,2,ilc_)+xr(in_)*rz;
        end
      end
    end
    return
  end
end

% -------------------------------------------------------------------------
function [vix, viy] = reduction_rate(c_g, Ne, A, F, lcdir)
% 柱梁耐力比算定用の軸力による全塑性曲げモーメント低下率の算定

% 定数
nlc = length(lcdir);
nme = length(c_g);
nmec = sum(+(c_g==PRM.COLUMN));

% 計算の準備

% 低下率の算定
vi = zeros(nmec,5);
% m = 1;
immm = 1:nme;
iccc = immm(c_g==PRM.COLUMN);
% for i = immm(c_g==PRM.COLUMN)
for ilc = 1:nlc
  switch lcdir(ilc)
    case PRM.EXP
      id = PRM.EXP;
    case PRM.EXN
      id = PRM.EXN;
    case PRM.EYP
      id = PRM.EYP;
    case PRM.EYN
      id = PRM.EYN;
    otherwise
      continue
  end
  Nraw = abs(Ne(iccc,id));
  Nr = Nraw./(A(iccc).*F(iccc)*1.1);
  % Nxmax = absmax(Nraw(1), Nraw(3));
  % Nymax = absmax(Nraw(2), Nraw(4));
  % nx = Nxmax /(A(i)*F(jel(i))*1.1);
  % ny = Nymax /(A(i)*F(jel(i))*1.1);
  innn = Nr<=0.5;
  vi(innn,id) = 1-4*Nr(innn).^2/3;
  vi(~innn,id) = 4*(1-Nr(~innn))/3;
  % if nx <= 0.5
  %   vix(m) = 1-4*nx^2/3;
  % else
  %   vix(m) = 4*(1-nx)/3;
  % end
  % if ny <= 0.5
  %   viy(m) = 1-4*ny^2/3;
  % else
  %   viy(m) = 4*(1-ny)/ 3;
  % end
  % m = m+1;
end
vix = vi(:,[PRM.EXP PRM.EXN]);
viy = vi(:,[PRM.EYP PRM.EYN]);
return
end

% -------------------------------------------------------------------------
% function [st, stc] = stress(...
%   rs, Mc, A, Asy, Asz, Aw, Zy, Zz, Zyf, Zyc, mtype)
% % 応力から応力度を計算する
% 
% % 計算の準備
% [nme, ~, nlc] = size(rs);
% 
% % 応力度の計算
% st = zeros(nme,12,nlc);
% stc = zeros(nme,nlc);
% Zz(mtype==PRM.BRACE) = 1.d-6;
% Asz(mtype==PRM.GIRDER) = Aw(mtype==PRM.GIRDER);
% for ilc = 1:nlc
%   st(:,1,ilc) = rs(:,1,ilc)./A;
%   st(:,2,ilc) = rs(:,2,ilc)./Asy;
%   st(:,3,ilc) = rs(:,3,ilc)./Asz;
%   st(:,6,ilc) = rs(:,6,ilc)./Zz;
%   st(:,7,ilc) = rs(:,7,ilc)./A;
%   st(:,8,ilc) = rs(:,8,ilc)./Asy;
%   st(:,9,ilc) = rs(:,9,ilc)./Asz;
%   st(:,12,ilc) = rs(:,12,ilc)./Zz;
%   for im = 1:nme
%     switch mtype(im)
%       case PRM.GIRDER
%         st(im,5,ilc) = rs(im,5,ilc)/Zyf(im);
%         st(im,11,ilc) = rs(im,11,ilc)/Zyf(im);
%         stc(im,ilc) = Mc(im,ilc)/Zyc(im);
%       case PRM.COLUMN
%         st(im,5,ilc) = rs(im,5,ilc)/Zy(im);
%         st(im,11,ilc) = rs(im,11,ilc)/Zy(im);
%     end
%   end
% end
% 
% return
% end

% -------------------------------------------------------------------------
function [fvec, ar] = modify_force_for_pinjoint(fvec0, ar0, mejoint)
% 初期化
fvec = fvec0;
ar = ar0;

% ピン節点の外力解除
isipin = mejoint(:,1) == PRM.PIN;
isjpin = mejoint(:,2) == PRM.PIN;

% 長期のみ
ar(isipin,5,1) = 0;
ar(isjpin,11,1) = 0;
return
end
