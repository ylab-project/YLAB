function [msprop, secdim, dvec, dnode, felement, stn, stcn, ...
  Mc, C, vix, viy, rvec, rs, dfn, rvec0, rs0, Mc0, dfn0, ...
  state, sw, lf, lr, lm, lm_weight, lnm, lbnm, Iy0, Iz0, ...
  gphiI, gphiN, cphiI, cbs, baseline, node, story, floor, ...
  Cn, nomgc] = analysis_frame(xvar, com, options)

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
matG = com.material.G;
matisSN = com.material.isSN;
floor = com.floor;
% fvec = com.feqvec;
jdof = com.node.dof;
% Lb = com.member.girder.Lb;
is_through_girder = com.member.girder.isthrough;
lbng = com.nominal.girder.stiffening_lb;
lcdir = com.loadcase.dir;
material = com.material;
section = com.section;
member = com.member;
member_column = com.member.column;
% member_column = table2struct(com.member.column,"ToScalar",true);
if istable(com.member.girder)
  member_girder = table2struct(com.member.girder,"ToScalar",true);
else
  member_girder = com.member.girder;
end
if istable(com.member.brace)
  member_brace = table2struct(com.member.brace,"ToScalar",true);
else
  member_brace = com.member.brace;
end
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
slab.width_lower = com.member.girder.slab_width_lower;
slab.thickness_lower = com.member.girder.slab_thickness_lower;
story = com.story;
stype = com.section.property.type;
% stress_factor = com.sectionList.design_stress_factor(idmc2slist);
xr = com.node.xr;
yr = com.node.yr;
fnode = com.fnode;
faddnode = com.faddnode;
felement = com.felement;

%% ---
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
Asc = msprop.Asc;
Asy = msprop.Asy;
Asz = msprop.Asz;
Aw = msprop.Aw;
% Af = msprop.Af;
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
Gm = zeros(nme,1); Gm(idm2mat>0) = matG(idm2mat(idm2mat>0));
isSNm = zeros(nme,1); isSNm(idm2mat>0) = matisSN(idm2mat(idm2mat>0));

% 水平ブレース
for isechb = 1:nsechb
  isec = section.horizontal_brace.idsec(isechb);
  Em(idm2s==isec) = section.horizontal_brace.E(isechb);
end

% 引張ブレース
Em(stype(idm2s) == PRM.TB) = PRM.ES;

% 結果の保存
msprop.E = Em;
% msprop.F = Fm;  % 既に108行目で設定済み
msprop.pr = prm;
msprop.G = Gm;
msprop.isSN = isSNm;

% 構造体への変換
msprop = table2struct(msprop,"ToScalar",true);

% 設計応力割増
sec_stress_factor = secmgr.getSectionStressFactor(ids2slist);
stress_factor = sec_stress_factor(idm2s);

% 床による梁剛性の考慮（合成梁）
[Igm, gphiI] = calc_composite_girder_Iy(member_girder, ...
  msdim, msprop, idmg2m, options);
Iy(idmg2m) = Igm;

% 床による軸断面積の増大率（出力用）
[~, gphiN] = calc_composite_girder_Asy(member_girder, ...
  msdim, msprop, idmg2m);

% 柱の剛度増減率
cphiI = member_column.phiI;
Iy(mtype==PRM.COLUMN) = Iy(mtype==PRM.COLUMN).*cphiI(:,1);
Iz(mtype==PRM.COLUMN) = Iz(mtype==PRM.COLUMN).*cphiI(:,2);

% その他
Zy = msprop.Zy;
Zz = msprop.Zz;
Zyf = msprop.Zyf;
Zysc = msprop.Zysc;
JJ = msprop.JJ;

%% 柱脚剛性の計算
Dcb = secdim(idsc2s(column_base.idsecc),1);
cbs = calc_column_base_section(Dcb, cbstiff, column_base, ...
  column_base_list);
cbstiff = cbs.stiff;

%% 形状の更新
[~, zcoord, nodez, cxl, cyl, lm, lf, lr, story, floor] = ...
  update_geometry(secdim, baseline, node, story, floor, ...
  section, member, cbs, options, idsup2n);
member_property.cxl = cxl;
member_property.cyl = cyl;
baseline.z.coord = zcoord;
node.z = nodez;
lrxm = zeros(nme,2);
lrxm(mtype==PRM.COLUMN,:) = lr.columnx;
lrxm(mtype==PRM.GIRDER,:) = lr.girder;
lrym = zeros(nme,2);
lrym(mtype==PRM.COLUMN,:) = lr.columny;

%% 分割部材の剛域・断面性能修正
isrigid_xm = sum(lrxm,2)>=lm;
isrigid_ym = sum(lrym,2)>=lm;
lrxm(isrigid_xm,1) = 0;
lrxm(isrigid_xm,2) = 0;
lrym(isrigid_ym,1) = 0;
lrym(isrigid_ym,2) = 0;
Iy0 = Iy; Iz0 = Iz;
Iy(isrigid_xm) = Iy(isrigid_xm)*PRM.RIGID_SCALE;
Iz(isrigid_ym) = Iz(isrigid_ym)*PRM.RIGID_SCALE;

% 通し部材の部材長（構造階高ベース）
lnm = lm;
idmeg = nominal_girder.idmeg;

% 通し梁長さ
lnm(mtype==PRM.GIRDER) = calc_nominal_girder_length( ...
  idmeg, lm(mtype==PRM.GIRDER));

% 通し柱長さ
lnm(mtype==PRM.COLUMN) = calc_nominal_column_length( ...
  nominal_column, lm(mtype==PRM.COLUMN));

% 名目梁4検定位置のlb/xc/sub情報を算定
lfg = lf.girder;
nomgc = calc_nominal_girder_check_interval(lbng, lm(mtype==PRM.GIRDER), ...
  lfg, idmeg);
lbnc = update_lb_nominal_column(lm(mtype==PRM.COLUMN), ...
  lnm(mtype==PRM.COLUMN), nominal_column);
idg2ng = member_girder.idnominal(:,1);
lbnm = zeros(nme,4);
lbnm(mtype==PRM.GIRDER,:) = nomgc.lb(idg2ng, :);
lbnm(mtype==PRM.COLUMN,1:3) = lbnc;

% 等価外力（要素荷重）の更新
felement = update_felement(felement, ar, cxl, cyl, idn2df, idm2n);
fvec = fnode+faddnode-felement;

%% 柱梁端部の結合条件
% mejoint: 1:X柱脚, 2:X柱頭, 3:Y柱脚, 4:Y柱頭
gjoint = member_girder.joint;
cjoint = member_column.joint;
mejoint = PRM.FIX*ones(nme,4);
mejoint(idmg2m,:) = gjoint;
mejoint(idmc2m,:) = cjoint;

%% 荷重計算用の部材長を算出（自重計算の有無にかかわらず常に計算）
stype_sec = com.section.property.type;
lm_column_weight = calc_column_weight_length(member_column, ...
  member_girder, floor, com.node, stype_sec, com.section.column.idsec, ...
  com.section.girder.idsec, secdim);

%% 基礎柱面寸法の配列（統一断面ID→Df）
Df_foundation = zeros(size(secdim, 1), 1);
for icb = 1:length(column_base.idsecc)
  if cbs.Df(icb) > 0
    ids_ = idsc2s(column_base.idsecc(icb));
    Df_foundation(ids_) = cbs.Df(icb);
  end
end

[lm_girder_weight, face_deduct] = ...
  calc_girder_weight_length(member_girder, com.node, ...
  stype_sec, com.section.girder.idsec, secdim, Df_foundation);

%% 柱・梁を結合して全部材の荷重計算用部材長を作成
lm_weight = lm;  % 初期値は構造階高ベースの部材長
lm_weight(mtype==PRM.COLUMN) = lm_column_weight;
lm_weight(mtype==PRM.GIRDER) = lm_girder_weight;

%% BRB単位重量の取得
brace_unit_weight = calc_brb_unit_weight(com.section.brace, ...
  com.member.brace, com.secmgr, secdim);

%% RC密度の計算（Fc依存: SS7マニュアル表2.1）
idmat_sec = com.section.property.idmaterial;
Fc_sec = zeros(size(idmat_sec));
valid = idmat_sec > 0;
Fc_sec(valid) = com.material.F(idmat_sec(valid));
rho_rc_sec = calc_rc_density(Fc_sec);
rho_rc_member = rho_rc_sec(idm2s);

%% 自重の計算
if options.consider_self_weight && options.consider_finishing_material
  sw = comp_self_weight(A, lm_weight, lm, member_property, ...
    msdim, slab, idn2df, ndf, mejoint, face_deduct, options, ...
    member_column, brace_unit_weight, Df_foundation, idsup2n, ...
    rho_rc_member);
  fvec(:,1) = fvec(:,1)-sw.f;
  ar(:,:,1) = ar(:,:,1)+sw.ar;
  M0(:,1)= M0(:,1)+sw.M0;
else
  sw.ar = zeros(nme,12);
  sw.f = zeros(ndf,1);
  sw.fc = zeros(ndf,1);
  sw.fg = zeros(ndf,1);
  sw.fw = zeros(ndf,1);
  sw.M0 = zeros(nme,1);
end

%% 計算条件
flag = struct("consider_shear_deformation", ...
  options.consider_shear_deformation);

%% ピン節点の外力解除
[fvec, ar] = modify_force_for_pinjoint(fvec, ar, mejoint);

%% λeによる引張のみブレース判定
is_steel_brace = (mtype == PRM.BRACE) ...
  & (stype(idm2s) == PRM.BHSR | stype(idm2s) == PRM.BHSS ...
  | stype(idm2s) == PRM.BWFS);
is_tension = false(nme, 1);
if any(is_steel_brace)
  % ブレース長さ L で λe を算定（SS7 3.8.1）
  lm_brace_buckling = calc_brace_buckling_length(member.brace, ...
    com.member.girder, node, stype, com.section.girder.idsec, ...
    secdim);
  lk_all = lm;
  lk_all(mtype==PRM.BRACE) = lm_brace_buckling;
  iy_ = sqrt(Iy(is_steel_brace) ./ A(is_steel_brace));
  iz_ = sqrt(Iz(is_steel_brace) ./ A(is_steel_brace));
  imin_ = min(iy_, iz_);
  lam_e = lk_all(is_steel_brace) ./ imin_;
  F_ = Fm(is_steel_brace);
  is_tension(is_steel_brace) = lam_e >= 1980 ./ sqrt(F_);
end

%% 水平ブレース引張のみ判定
is_tension_hb = com.member.property.is_tension_only_hb;
is_tension = is_tension | is_tension_hb;

%% 引張ブレースの判定（TB + λe判定鋼材 + 水平ブレース引張のみ）
has_tension_brace = any(stype(idm2s) == PRM.TB) || any(is_tension);

if options.consider_foundation_uplift || has_tension_brace
  iter_max = 30;
else
  iter_max = 1;
end

%% ブレース剛性の事前計算
br_stif = precompute_brace_stiffness(A, cxl, cyl, lm, ...
  Em, JJ, Gm, xr, yr, idn2df, idm2n1, idm2n2, mtype, ...
  stype, idm2s, is_tension);
if has_tension_brace
  id_tb = find([br_stif.is_tb]);
  ntb = length(id_tb);
end

%% 剛性行列の作成
ksmat0 = stif_sys_matrix(A, Asy, Asz, Iy, Iz, JJ, cxl, ...
  cyl, lm, Em, Gm, xr, yr, lrxm, lrym, cbstiff, mtype, ...
  idn2df, idf2n, idm2n1, idm2n2, idm2scb, mejoint, ndf, ...
  nbw, flag, br_stif);

%% 初期化
isuplifted = false(nsup, nlc);
if has_tension_brace
  iscompressed = false(ntb, nlc);
end
dvec = zeros(ndf, nlc);
dnode = zeros(nnode,6,nlc);
sks = zeros(ns6, nlc);
% rs = zeros(nme, 12, nlc);
frvec = zeros(ndf, nlc);
rvec = zeros(ns6, nlc);

%% 解析ループ
if ~options.consider_foundation_uplift && ~has_tension_brace
  %% Fast path: 浮き上がり・引張ブレースなし
  ilcset_ = 1:nlc;
  isuplifted_ = false(nsup, 1);
  [ksmat, sks] = add_sup_stif(ksmat0, xr, yr, idsup2n, ...
    isfixedsup, isuplifted_, idn2df);
  dvec = eqsoln(ksmat, fvec, nbw, ndf);
  sks = repmat(sks, 1, nlc);
  dnode = trans_dvec2dnode(ilcset_, dnode, dvec);
  rvec = reaction_force(ilcset_, dnode, frvec, rvec, ...
    sks, xr, yr, idn2df, idsup2n, isfixedsup);
else
  %% === 統合収束ループ（G+P + 地震） ===
  for ilc = 1:nlc
    for iter = 1:iter_max
      % TB剛性減算（共通）
      if has_tension_brace && any(iscompressed(:, ilc))
        ksmat = subtract_brace_stiffness(ksmat0, br_stif, ...
          id_tb, iscompressed(:, ilc));
      else
        ksmat = ksmat0;
      end
      % 支点剛性（共通）
      [ksmat, sks(:,ilc)] = add_sup_stif(ksmat, xr, ...
        yr, idsup2n, isfixedsup, isuplifted(:,ilc), idn2df);
      % 外力ベクトル（G+P/地震で分岐）
      if ilc == 1
        frvec_ilc_ = fvec(:, 1);
      else
        if options.consider_foundation_uplift
          frvec_ilc_ = uplift_force_case(idn2df, idsup2n, ...
            isfixedsup, rvec, fvec(:,ilc), isuplifted(:,ilc));
        else
          frvec_ilc_ = fvec(:, ilc);
        end
        % G+P外力補正
        if has_tension_brace && any(iscompressed(:, ilc))
          frvec_ilc_ = frvec_ilc_ + calc_tb_gp_force( ...
            br_stif, id_tb, dvec(:, 1), iscompressed(:, ilc), ...
            iscompressed(:, 1));
        end
      end
      % 変位計算
      dvec(:,ilc) = eqsoln(ksmat, frvec_ilc_, nbw, ndf);
      % 収束判定
      converged_ = true;
      % TB圧縮判定
      if has_tension_brace
        iscompressed_prev_ = iscompressed(:, ilc);
        if ilc == 1
          iscompressed(:, 1) = check_brace_compression_case( ...
            br_stif, id_tb, dvec, 1, iscompressed(:, 1), []);
        else
          iscompressed(:, ilc) = check_brace_compression_case( ...
            br_stif, id_tb, dvec, ilc, iscompressed(:, ilc), ...
            iscompressed(:, 1));
        end
        if ~all(iscompressed(:, ilc) == iscompressed_prev_)
          converged_ = false;
        end
      end
      % 浮き上がり判定（地震のみ）
      if ilc >= 2 && options.consider_foundation_uplift
        isuplifted_prev_ = isuplifted(:, ilc);
        isuplifted(:, ilc) = check_uplift_case(idn2df, ...
          idsup2n, isfixedsup, dvec, ilc);
        if ~all(isuplifted(:, ilc) == isuplifted_prev_)
          converged_ = false;
        end
      end
      if converged_
        break
      end
    end
    % G+P後処理（ilc=1完了時のみ）
    if ilc == 1
      dnode = trans_dvec2dnode(1, dnode, dvec);
      rvec = reaction_force(1, dnode, frvec, rvec, sks, ...
        xr, yr, idn2df, idsup2n, isfixedsup);
      if options.consider_foundation_uplift
        frvec = uplift_force(idn2df, idm2n1, idsup2n, ...
          isfixedsup, rvec, fvec, isuplifted);
      else
        frvec = fvec;
      end
    end
  end

  %% 全ケース完了後: frvec, dnode, rvec確定
  if options.consider_foundation_uplift
    frvec = uplift_force(idn2df, idm2n1, idsup2n, isfixedsup, ...
      rvec, fvec, isuplifted);
  end
  dnode = trans_dvec2dnode(2:nlc, dnode, dvec);
  rvec = reaction_force(2:nlc, dnode, frvec, rvec, sks, ...
    xr, yr, idn2df, idsup2n, isfixedsup);
end

% 応力計算
[rs, Mc] = calc_member_force(1:nlc, dvec, [], frvec, ...
  sks, M0, ar, A, Asy, Asz, Iy, Iz, JJ, Em, Gm, lm, ...
  lrxm, lrym, flag, member_property, node, material, ...
  cbstiff, idm2mat, idm2scb, mejoint, br_stif);

% 斜め柱応力を全体系XY方向に変換（SS7互換）
rs = trans_column_force_global_xy(rs, cxl, cyl, idmc2m);

rs0 = rs; Mc0 = Mc; rvec0 = rvec;

%% 圧縮除去ブレースの応力処理（重ね合わせ前）
% G+P非圧縮・地震圧縮: 定数項 -rs0(:,:,1) を設定
%   → 重ね合わせで G+P + (-G+P) = 0
% G+P圧縮: ゼロクリア（G+P力なし）
if has_tension_brace
  for itb = 1:ntb
    im = br_stif(id_tb(itb)).im;
    for ilc = 1:nlc
      if iscompressed(itb, ilc)
        if iscompressed(itb, 1)
          rs0(im, :, ilc) = 0;
        else
          rs0(im, :, ilc) = -rs0(im, :, 1);
        end
      end
    end
  end
end

%% Kブレース分割梁のせん断力補正
rs0 = correct_kbrace_shear(rs0, node.type, member_girder, ...
  member_brace, cxl, idm2n1, idm2n2);

%% 荷重ケースの重ね合わせ
[rs, Mc, rvec, cgsrn] = superpose_analysis_case(rs0, ...
  Mc0, rvec0, lcdir, idmc2m, idmg2m, lm, lf, stress_factor);

%% state 構造体の構築
state.sup.islifted = isuplifted;
if has_tension_brace
  state.tb.iscompressed = iscompressed;
else
  state.tb.iscompressed = [];
end
state.tb.is_tension = is_tension(com.member.brace.idme);

%% 設計応力の計算
df0 = calc_design_force(rs0, lcdir, idmc2m, idmg2m, lm, lf);
dfn0 = calc_nominal_design_force(df0, nominal_property);
dfn = superpose_design_force(dfn0, lcdir);

% 名目部材レベルの中央M（ケース別→重ね合わせ）
% M0 は L287 で sw.M0 加算済み
idnmg2nm = nominal_girder.idnominal;
Mcn0 = calc_nominal_Mc(rs0, M0, Mc0(idnm2m(:,1), :), ...
  idmeg, idmg2m, idnmg2nm, lm, lf);
Mcn = superpose_design_force(Mcn0, lcdir);
nomgc.Mcn = squeeze(Mcn);
nomgc.Mcn0 = squeeze(Mcn0);

% 名目部材レベルの中央N（ケース別→重ね合わせ）
nnm = size(idnm2m, 1);
Ncn0 = calc_nominal_Nc(df0, idmeg, idmg2m, idnmg2nm, nnm, lm, lf);
Ncn = superpose_design_force(Ncn0, lcdir);
nomgc.Ncn = squeeze(Ncn);

%% 許容応力度計算用の係数算定
[C, ~] = calc_modified_C(rs, M0, lm, lbng, nomgc.xc, ...
  idm2mg, is_through_girder, idmeg, Mc);
Cn = calc_modified_Cn(rs, M0, lm, nomgc, idm2mg, is_through_girder, idmeg);

%% 柱梁耐力比算定用の軸力による全塑性曲げモーメント低下率の算定
[vix, viy] = reduction_rate(mtype, cgsrn, A, Fm, lcdir);

%% 応力度計算
if options.consider_web_at_girder_center
  Zyc = Zy;
else
  Zyc = Zyf;
end

%% 材端部の断面係数（WFSのみにZysc/Zyfを適用）
mstype = stype(idm2s);
Zyij = Zy;  % デフォルトはZy（非ゼロ）
if options.consider_web_at_girder_end
  Zyij(mstype==PRM.WFS) = Zysc(mstype==PRM.WFS);
else
  Zyij(mstype==PRM.WFS) = Zyf(mstype==PRM.WFS);
end
% An = Aw+Af;
% [st, stc] = stress(rs, Mc, A, Asy, Asz, Aw, Zy, Zz, Zyij, Zyc, mtype);

[stn, stcn] = calc_nominal_stress(dfn, Mcn, Asc, Asy, ...
  Asz, Aw, Zy, Zz, Zyij, Zyc, mtype, idnm2m);
% -------------------------------------------------------------------------
  function dnode = trans_dvec2dnode(ilcset, dnode, dvec)
    % 剛床を考慮した節点変位への変換
    for in_=1:nnode
      % 吸収節点（idstory=0）はスキップ
      is_ = idn2st(in_);
      if is_==0, continue; end
      for ilc_=ilcset
        dnode(in_,:,ilc_) = dvec(jdof(in_,:),ilc_);
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

% -------------------------------------------------------------------------
function ksmat = subtract_brace_stiffness(ksmat0, br_stif, ...
  id_tb, iscompressed_ilc)
%subtract_brace_stiffness - 圧縮ブレースの剛性を減算
%
%   ksmat = subtract_brace_stiffness(ksmat0, br_stif, ...
%     id_tb, iscompressed_ilc) は、
%   基本剛性マトリクスから圧縮ブレースの寄与を
%   減算した剛性マトリクスを返す。
%
%   入力引数:
%     ksmat0 - 基本剛性マトリクス [ndf×nbw]
%     br_stif - ブレース構造体配列
%     id_tb - TBインデックス [1×ntb]
%     iscompressed_ilc - 圧縮状態 [ntb×1]
%
%   出力引数:
%     ksmat - 減算後の剛性マトリクス [ndf×nbw]

ksmat = ksmat0;
ntb_ = length(id_tb);

for itb = 1:ntb_
  if ~iscompressed_ilc(itb)
    continue
  end
  idx_ = id_tb(itb);
  ke_ = br_stif(idx_).ke;
  ndi_ = br_stif(idx_).ndi;
  for ii = 1:12
    for jj = 1:12
      kk = ndi_(jj) - ndi_(ii);
      if kk >= 0
        kk = kk + 1;
        ksmat(ndi_(ii), kk) = ksmat(ndi_(ii), kk) - ke_(ii, jj);
      end
    end
  end
end

return
end
