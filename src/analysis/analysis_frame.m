function [msprop, secdim, dvec, dnode, felement, stn, stcn, Mc, C, ...
  vix, viy, rvec, rs, dfn, rvec0, rs0, rs_analysis0, Mc0, ...
  dfn0, state, sw, lf, lr, lmem, lnm, lbnm, Iy0, Iz0, ...
  gphiI, gphiAs, gphiAn, cphiI, cbs, baseline, node, ...
  story, floor, Cn, nomgc] = analysis_frame(xvar, com, options)
%analysis_frame - 骨組のマトリクス解析本体（剛性組立・変位・応力算定）
%
%   [msprop, secdim, ...] = analysis_frame(xvar, com, options) は、
%   断面変数 xvar と共通オブジェクト com から、部材断面性能・剛性行列を
%   組み立て、荷重ケースごとの変位解析・部材応力算定・重ね合わせを行い、
%   公称部材レベルの設計応力度および関連諸元を算出する。引張ブレースの
%   圧縮除去および支点浮き上がりの収束ループを内部に含む。
%
%   入力引数:
%     xvar    - 断面変数ベクトル（最適化設計変数）
%     com     - 共通オブジェクト（節点・部材・断面・材料情報を保持）
%     options - 計算オプション構造体（剛床・自重・浮き上がり等のフラグ）
%
%   出力引数:
%     msprop   - 部材断面性能の構造体（A, Iy, Iz, E, F 等）
%     secdim   - 解析で使用された断面寸法 [nsec x ncol] mm
%     dvec     - 自由度別変位ベクトル [ndf x nlc]
%     dnode    - 節点変位（剛床補正後） [nnode x 6 x nlc]
%     felement - 等価節点荷重（要素荷重起因） [nnode x 6 x nlc]
%     stn      - 公称部材の応力度（一般位置） 構造体
%     stcn     - 公称部材の応力度（中央位置） 構造体
%     Mc       - 部材中央曲げモーメント（重ね合わせ後）
%     C        - 許容応力度計算用の係数（端部用）
%     vix      - 軸力による全塑性曲げ低下率（X方向）
%     viy      - 軸力による全塑性曲げ低下率（Y方向）
%     rvec     - 部材端応力ベクトル（重ね合わせ後） [ns6 x nlc]
%     rs       - 部材応力（重ね合わせ後） [nme x 12 x nlc]
%     dfn      - 公称部材の設計応力（重ね合わせ後）
%     rvec0    - 部材端応力ベクトル（ケース別・重ね合わせ前）
%     rs0      - 部材応力（ケース別・重ね合わせ前）
%     rs_analysis0 - 部材応力（ケース別・解析基底）
%     Mc0      - 部材中央曲げモーメント（ケース別）
%     dfn0     - 公称部材の設計応力（ケース別）
%     state    - 収束状態（sup.islifted, tb.iscompressed 等の構造体）
%     sw       - 自重情報（sw.ar, sw.f, sw.M0 等の構造体）
%     lf       - 両端フェイス長（柱X/柱Y/梁） 構造体
%     lr       - 両端剛域長（柱X/柱Y/梁） 構造体
%     lmem     - 部材長構造体 struct('geom','stiff','weight') 各 [nme x 1]
%     lnm      - 通し部材長（通し柱・通し梁ベース） [nme x 1]
%     lbnm     - 名目部材の横補剛区間長 [nme x 4]
%     Iy0      - 剛域スケール前の Iy [nme x 1]
%     Iz0      - 剛域スケール前の Iz [nme x 1]
%     gphiI    - 合成梁の曲げ剛性増大率
%     gphiAs   - 梁せん断断面積増大率
%     gphiAn   - 梁軸断面積増大率
%     cphiI    - 柱の曲げ剛度増減率 [nmec x 2]
%     cbs      - 柱脚断面情報（calc_column_base_section の出力）
%     baseline - 基線情報（Z座標更新後）
%     node     - 節点情報（Z座標更新後）
%     story    - ストーリー情報（形状更新後）
%     floor    - フロア情報（形状更新後）
%     Cn       - 許容応力度計算用の係数（公称部材用）
%     nomgc    - 公称梁の検定位置情報（lb, xc, Mcn, Ncn 等）
%
%   備考:
%     - 引張ブレース・支点浮き上がりが無い場合は Fast path を使用する。
%     - 詳細な処理フローおよび各サブ関数の仕様は、本ファイル内の
%       セクション見出しおよび呼び出し先関数のヘッダを参照。

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
matE = com.material.E;
matF = com.material.F;
matpr = com.material.pr;
matG = com.material.G;
matisSN = com.material.isSN;
matsteel_grade = com.material.steel_grade;
matname = com.material.name;
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
fnode = com.fnode;  % (nnode, 6, nlc)
faddnode = com.faddnode;  % (nnode, 6, nlc)

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
steel_grade_m = zeros(nme,1);
steel_grade_m(idm2mat>0) = matsteel_grade(idm2mat(idm2mat>0));
material_name_m = repmat({''}, nme, 1);
material_name_m(idm2mat>0) = matname(idm2mat(idm2mat>0));

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
msprop.steel_grade = steel_grade_m;
msprop.idmaterial = idm2mat;
msprop.material_name = material_name_m;

% 構造体への変換
msprop = table2struct(msprop,"ToScalar",true);

% 設計応力割増
sec_stress_factor = secmgr.getSectionStressFactor(ids2slist);
stress_factor = sec_stress_factor(idm2s);

% 床による梁剛性の考慮（合成梁）
[Igm, gphiI] = calc_composite_girder_Iy(member_girder, ...
  msdim, msprop, idmg2m, options);
Iy(idmg2m) = Igm;

% 床組と直接指定による梁せん断断面積の増大率
[Asygm, gphiAs] = calc_composite_girder_Asy(member_girder, ...
  msdim, msprop, idmg2m, options);
Asy(idmg2m) = Asygm;

% 床組と直接指定による梁軸断面積の増大率
[Agm, gphiAn] = calc_composite_girder_An(member_girder, ...
  msprop, idmg2m, options);
An = A;
An(idmg2m) = Agm;

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
[mglevel, zcoord, nodez, cxl, cyl, lm, lf, lr, story, floor] = ...
  update_geometry(secdim, baseline, node, story, floor, ...
  section, member, cbs, options, idsup2n);
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
stiffening_info = struct();
if has_table_field(nominal_girder, 'stiffening_lb_end')
  stiffening_info.lb_end = nominal_girder.stiffening_lb_end;
end
if has_table_field(nominal_girder, 'stiffening_xc_points')
  stiffening_info.xc_points = nominal_girder.stiffening_xc_points;
end
if has_table_field(nominal_girder, 'stiffening_xc')
  stiffening_info.xc = nominal_girder.stiffening_xc;
end
if has_table_field(nominal_girder, 'stiffening_xc_bounds')
  stiffening_info.xc_bounds = nominal_girder.stiffening_xc_bounds;
end
nomgc = calc_nominal_girder_check_interval(lbng, lm(mtype==PRM.GIRDER), ...
  lfg, idmeg, stiffening_info);
lbnc = update_lb_nominal_column(lm(mtype==PRM.COLUMN), ...
  lnm(mtype==PRM.COLUMN), nominal_column);
idg2ng = member_girder.idnominal(:,1);
lbnm = zeros(nme,4);
lbnm(mtype==PRM.GIRDER,:) = nomgc.lb(idg2ng, :);
lbnm(mtype==PRM.COLUMN,1:3) = lbnc;

% 等価外力（要素荷重）の更新
felement = update_felement(ar, cxl, cyl, idm2n, nnode, nlc);

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

%% 通り心と構造心のズレ（通り心まで端の自重用基準点補正量）
coord_shift = calc_baseline_coord_shift(baseline, com.span);

[lm_girder_weight, face_deduct] = ...
  calc_girder_weight_length(member_girder, com.node, ...
  member_property.cxl(idmg2m, :), stype_sec, com.section.girder.idsec, ...
  secdim, Df_foundation, coord_shift);

%% ブレース座屈長（SS7 3.8.1）
lm_brace_buckling = calc_brace_buckling_length(member.brace, ...
  com.member.girder, node, stype_sec, com.section.girder.idsec, ...
  secdim);

%% 剛性計算用部材長（全部材で節点間距離を使用）
lm_stiff = lm;

%% 柱・梁・ブレースを結合して全部材の荷重計算用部材長を作成
% ブレース重量はSS7 4.1.9に従い、SS7 3.8.1のブレース長さL
% を使う
lm_weight = lm;
lm_weight(mtype==PRM.COLUMN) = lm_column_weight;
lm_weight(mtype==PRM.GIRDER) = lm_girder_weight;
lm_weight(mtype==PRM.BRACE) = lm_brace_buckling;

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
  sw = comp_self_weight(A, lm_weight, lm, member_property, msdim, ...
    slab, cxl, cyl, nnode, mejoint, face_deduct, options, ...
    member_column, brace_unit_weight, Df_foundation, mglevel, ...
    member_girder.isfg, idsup2n, rho_rc_member);
  ar(:,:,1) = ar(:,:,1)+sw.ar;
  M0(:,1)= M0(:,1)+sw.M0;
else
  sw.ar = zeros(nme,12);
  sw.f = zeros(nnode, 6);
  sw.fc = zeros(nnode, 6);
  sw.fg = zeros(nnode, 6);
  sw.fw = zeros(nnode, 6);
  sw.M0 = zeros(nme,1);
end

%% 等価節点荷重ベクトルの一括集約
% fnode は重心作用とみなし偏心 Mz 非加算、他は偏心 Mz 加算
sw_f_lc = zeros(nnode, 6, nlc);
sw_f_lc(:, :, 1) = sw.f;
fnode_dof = node_to_dof_vec(fnode, node, story, ndf, false);
rest_dof = node_to_dof_vec(faddnode - felement - sw_f_lc, ...
  node, story, ndf, true);
fvec = fnode_dof + rest_dof;

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
  % λe 判定（SS7 3.8.1、Lk = L、K=1）
  iy_ = sqrt(Iy(is_steel_brace) ./ A(is_steel_brace));
  iz_ = sqrt(Iz(is_steel_brace) ./ A(is_steel_brace));
  imin_ = min(iy_, iz_);
  lam_e = lm_brace_buckling(is_steel_brace(mtype == PRM.BRACE)) ./ imin_;
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

%% 捩り剛性増減率（ブレース・梁柱で共通利用）
factor_J = com.member.property.factor_J;

%% ブレース剛性の事前計算（軸剛性はブレース長さ L = 内法）
br_stif = precompute_brace_stiffness(A, cxl, cyl, lm_stiff, ...
  Em, JJ, Gm, xr, yr, idn2df, idm2n1, idm2n2, mtype, ...
  stype, idm2s, is_tension, factor_J);
if has_tension_brace
  id_tb = find([br_stif.is_tb]);
  ntb = length(id_tb);
end

%% 剛性行列の作成
hstiff_type = options.girder_horizontal_stiffness_type;
ksmat0 = stif_sys_matrix(An, Asy, Asz, Iy, Iz, JJ, cxl, ...
  cyl, lm_stiff, Em, Gm, xr, yr, lrxm, lrym, cbstiff, mtype, ...
  idn2df, idf2n, idm2n1, idm2n2, idm2scb, mejoint, ndf, ...
  nbw, flag, br_stif, hstiff_type, factor_J);
validate_node_rotational_stiffness(ksmat0, node, idf2n, idsup2n, ...
  isfixedsup, idn2df);

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
  sks, M0, ar, An, Asy, Asz, Iy, Iz, JJ, Em, Gm, lm_stiff, ...
  lrxm, lrym, flag, cxl, cyl, member_property, node, material, ...
  cbstiff, idm2mat, idm2scb, mejoint, br_stif, hstiff_type);

% 水平力分担・β用に解析基底のケース別応力を保持
rs_analysis0 = rs;

% 部材応力をSS7互換の表示基底へ変換
rs = trans_member_force_global_basis(rs, cxl, cyl, mtype, idmc2m);

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
          rs_analysis0(im, :, ilc) = 0;
        else
          rs0(im, :, ilc) = -rs0(im, :, 1);
          rs_analysis0(im, :, ilc) = -rs_analysis0(im, :, 1);
        end
      end
    end
  end
end

%% Kブレース分割梁のせん断力補正
[rs0, kbrace_corr] = correct_kbrace_shear(rs0, node.type, ...
  member_girder, member_brace, cxl, idm2n1, idm2n2, lcdir);
rs_analysis0 = correct_kbrace_shear(rs_analysis0, node.type, ...
  member_girder, member_brace, cxl, idm2n1, idm2n2, lcdir);

%% 荷重ケースの重ね合わせ
[rs, Mc, rvec, cgsrn] = superpose_analysis_case(rs0, ...
  Mc0, rvec0, lcdir, stress_factor);

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
% SS7: 設計用せん断力 Q_D = Q_L + n*Q_E の割増率 n は、
% RC造梁のみに適用する（S造梁は対象外。S造は6.4、RC造は6.9参照）
n_beam = PRM.route_to_n_beam(options.design_route);
stype_nm = stype(idm2s(nominal_property.idme(:,1)));
is_rc_girder_nm = nominal_property.mtype == PRM.GIRDER ...
  & stype_nm == PRM.RCRS;
dfn = superpose_design_force(dfn0, lcdir, is_rc_girder_nm, n_beam);

% 名目部材レベルの中央M（ケース別→重ね合わせ）
% M0 は sw.M0 加算済み
idnmg2nm = nominal_girder.idnominal;
Mcn0 = calc_nominal_Mc(rs0, M0, Mc0(idnm2m(:,1), :), ...
  idmeg, idmg2m, idnmg2nm, lm, lf, kbrace_corr);
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
[stn, stcn] = calc_nominal_stress(dfn, Mcn, A, Asc, Asy, ...
  Asz, Aw, Zy, Zz, Zyij, Zyc, msdim, mstype, Fm, mtype, idnm2m);

%% 部材長構造体の組立て（戻り値）
% buckling はブレース座屈長用（暫定。後日 lnom.buckling に整理）
lm_buckling = lm;
lm_buckling(mtype==PRM.BRACE) = lm_brace_buckling;
lmem = struct('stiff', lm_stiff, 'buckling', lm_buckling, ...
  'weight', lm_weight);
% -------------------------------------------------------------------------
  function dnode = trans_dvec2dnode(ilcset, dnode, dvec)
  %trans_dvec2dnode - 解ベクトルから節点変位への変換（剛床考慮）
  %
  %   dnode = trans_dvec2dnode(ilcset, dnode, dvec) は、
  %   自由度ベクトル dvec を節点変位配列 dnode に展開する。
  %   剛床属性の層では代表節点の回転から水平変位を補正する。
  %
  %   入力引数:
  %     ilcset - 対象荷重ケースの添字配列
  %     dnode - 節点変位配列（更新前） [nnode×6×nlc]
  %     dvec - 解ベクトル（自由度順） [ndof×nlc]
  %
  %   出力引数:
  %     dnode - 節点変位配列（更新後） [nnode×6×nlc]
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
%reduction_rate - 軸力による全塑性曲げモーメント低下率の算定
%
%   [vix, viy] = reduction_rate(c_g, Ne, A, F, lcdir) は、
%   柱梁耐力比算定用に、軸力比 Nr=|N|/(A*F*1.1) に基づき
%   X方向・Y方向地震時の低下率を柱部材について算定する。
%   Nr<=0.5 で 1-4*Nr^2/3、Nr>0.5 で 4*(1-Nr)/3 を与える。
%
%   入力引数:
%     c_g - 部材種別フラグ（PRM.COLUMN 等） [nme×1]
%     Ne - 荷重ケース別軸力 [nme×nlc]
%     A - 断面積 [nme×1]
%     F - 基準強度 [nme×1]
%     lcdir - 各荷重ケースの方向コード（PRM.EXP/EXN/EYP/EYN）
%
%   出力引数:
%     vix - X方向低下率 [nmec×2]（正負）
%     viy - Y方向低下率 [nmec×2]（正負）

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
  innn = Nr<=0.5;
  vi(innn,id) = 1-4*Nr(innn).^2/3;
  vi(~innn,id) = 4*(1-Nr(~innn))/3;
end
vix = vi(:,[PRM.EXP PRM.EXN]);
viy = vi(:,[PRM.EYP PRM.EYN]);
return
end

% -------------------------------------------------------------------------
function [fvec, ar] = modify_force_for_pinjoint(fvec0, ar0, mejoint)
%modify_force_for_pinjoint - ピン接合端の外力解除
%
%   [fvec, ar] = modify_force_for_pinjoint(fvec0, ar0, mejoint) は、
%   部材端接合条件 mejoint がピンの要素について、長期荷重ケース
%   （ilc=1）の材端モーメント成分を 0 にクリアする。
%
%   入力引数:
%     fvec0 - 節点荷重ベクトル（変更前）
%     ar0 - 部材材端力配列（変更前） [nme×12×nlc]
%     mejoint - 部材端接合条件 [nme×2]（1列目=i端, 2列目=j端）
%
%   出力引数:
%     fvec - 節点荷重ベクトル（現状は変更なし）
%     ar - 部材材端力配列（ピン端のモーメント=0に設定）

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

