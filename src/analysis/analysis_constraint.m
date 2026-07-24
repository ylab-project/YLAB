function [cvec, result, restoration] = analysis_constraint( ...
  xvar, secdim, com, options)
%analysis_constraint - 構造解析を実行し制約条件を評価する
%
%   [cvec, result, restoration] =
%     analysis_constraint(xvar, secdim, com, options) は、
%   フレーム解析を実行し、許容応力度比・層間変形・幅厚比等の
%   制約を評価して制約値ベクトルを返す。評価対象の制約は
%   options.coptions で制御する。
%
%   入力引数:
%     xvar    - 設計変数ベクトル [nvar×1]
%     secdim  - xvar から写像済みの断面寸法 [nsec×7]
%     com     - 共通データ構造体
%     options - 解析オプション構造体
%
%   出力引数:
%     cvec        - 制約値ベクトル [1×ncon]（正の値が制約違反）
%     result      - 詳細結果構造体（応力、変形、諸元等）
%     restoration - 復元用データ構造体
%
%   備考:
%     - xvar と secdim は同一評価点の整合ペアであることを前提とし、
%       本関数では対応検査も再写像も行わない。写像は呼出し側の責務
%       とする。設計変数だけを持つ境界では analysis_constraint_xvar
%       を使う。
%     - 関連関数: analysis_constraint_xvar, analysis_frame,
%       eval_nominal_allowable_stress_ratio

% 共通定数の取得
nsec = com.nsec;                              % 断面数
nme = com.nme;                                % 部材数
nng = size(com.nominal.girder.idmeg,1);      % 名目梁数
nnc = size(com.nominal.column.idmec,1);      % 名目柱数

% ID配列の取得
idn2st = com.node.idstory;                    % 節点→層番号
idc2n = [com.member.column.idnode1 ...        % 柱→節点番号 [nc×2]
  com.member.column.idnode2];
idfl2s = com.floor.idstory;                   % 階→層番号
idm2n = [com.member.property.idnode1 ...      % 部材→節点番号 [nme×2]
  com.member.property.idnode2];
idmg2m = com.member.girder.idme;              % 梁→部材番号
idmc2m = com.member.column.idme;              % 柱→部材番号
idmwfs2m = com.member.girder.idme(...         % H形梁→部材番号
  com.member.girder.section_type==PRM.WFS);
idm2s = com.member.property.idsec;            % 部材→断面番号
idmc2st = com.member.column.idstory;          % 柱→層番号
idncgsr = com.cgsr.idnode;                    % 柱梁耐力比評価節点番号
idsrep2s = com.section.representative.idsec;  % 代表断面→断面番号
% 代表断面→断面タイプ
idsrep2stype = com.section.representative.section_type;
height_smooth = com.height_smooth;      % 梁せい平滑化固定データ

% 共通配列の取得
dmax = 200;   % 層間変形角の制限値（1/dmax）
gdmax = 300;  % 梁たわみの制限値（1/gdmax）
idvarHgap = com.Hgap.idvar;                   % 梁せい差評価用変数番号
idvarDgap = com.Dgap.idvar;                   % 柱外径差評価用変数番号
idsecHgap = com.Hgap.idsec;                   % 梁せい差評価用断面番号
lcdir = com.loadcase.dir;                     % 荷重ケースの方向
mtype = com.member.property.type;             % 部材タイプ
mstype = com.member.property.section_type;    % 部材断面タイプ
idme2stype = com.member.property.section_type; % 部材→断面タイプ
M0 = com.M0;                                   % 付加曲げモーメント
secmgr = com.secmgr;                          % 断面管理オブジェクト
nominal = com.nominal;                         % 名目部材データ
idmg2mng = com.member.girder.idnominal;       % 梁→名目梁番号
idmc2mnc = com.member.column.idnominal;       % 柱→名目柱番号

% 細長比計算用データ
slr = genslr(com.member.girder);

% オプション設定と変数ベクトル化
coptions = options.coptions;                  % 制約オプション
xvar = xvar(:);                               % 設計変数を列ベクトルに

%% マトリクス解析
[msprop, dvec, dnode, felement, stn, stcn, Mc, C, vix, viy, ...
  rvec, rs, dfn, rvec0, rs0, rs_analysis0, Mc0, dfn0, ...
  state, sw, lf, lr, lmem, lnm, lb, Iy, Iz, gphiI, gphiAs, ...
  gphiAn, cphiI, cbs, baseline, node, story, floor, Cn, ...
  nomgc] = analysis_frame(secdim, com, options);
lm = lmem.stiff;
lm_weight = lmem.weight;

% 方向余弦を更新後の node 座標から再計算
[cxl, cyl] = update_member_cosine(com.member.girder, com.member.column, ...
  com.member.brace, com.member.horizontal_brace, node);

% 梁剛比の平面振れ角重み（柱座屈長さ係数算定用）
% SS7互換: 水平面内の振れ角のみ cos2θ を乗じ、鉛直傾きは考慮しない
[wgx, wgy] = calc_plane_direction_weights(cxl);
isxdir_member = com.cgsr.isxdir_member;
isydir_member = com.cgsr.isydir_member;

% 解析結果から断面諸元を取得
A = msprop.A;                                 % 断面積
Zy = msprop.Zy;                              % 弾性断面係数（Y軸）
Zpy = msprop.Zpy;                            % 塑性断面係数（Y軸）
Em = msprop.E;                               % ヤング率
Fm = msprop.F;                               % 基準強度
isSNmem = msprop.isSN;                       % SN材判定フラグ（部材）

% 断面ごとの基準強度を取得
[uidm2s, uidmem] = unique(idm2s);
ids2m = ones(nsec,1);
ids2m(uidm2s) = uidmem;
Fs = Fm(ids2m);                              % 断面の基準強度
isSNsec = isSNmem(ids2m);                    % SN材判定フラグ（断面）
grank = com.section.girder.rank;             % 梁断面ランク（制約用）
% 柱断面ランクを全断面ベクトルに展開（idhssrepが全断面IDのため）
crank = zeros(nsec, 1);
crank(com.section.column.idsec) = com.section.column.rank;

% H形梁の断面諸元を取得
Ag = A(idmwfs2m);                            % 断面積
Izg = Iz(idmwfs2m);                          % 断面二次モーメント（Z軸）
Zyg = Zy(idmwfs2m);                          % 弾性断面係数（Y軸）
Zpyg = Zpy(idmwfs2m);                        % 塑性断面係数（Y軸）
Fg = Fm(idmwfs2m);                           % 基準強度

% 梁たわみ計算用のモーメント
M0sw = M0+sw.M0;                             % 付加曲げ＋自重モーメント

% H形鋼の断面寸法（H×B×tw×tf×r）
msdim = secdim(idm2s,1:5);
msdimwfs = msdim(idme2stype==PRM.WFS,:);

% 階高データ
column_floor_height = com.member.column.floor_height;

% 梁・柱端部の結合条件の設定
gjoint = com.member.girder.joint;            % 梁の結合条件
cjoint = com.member.column.joint;            % 柱の結合条件
mejoint = PRM.FIX*ones(nme,4);              % 全部材を固定で初期化
mejoint(idmg2m,:) = gjoint;                  % 梁の結合条件を設定
mejoint(idmc2m,:) = cjoint;                  % 柱の結合条件を設定
isgmirrored = com.member.girder.ismirrored;  % 梁の左右反転フラグ

% 名目ブレースごとの水平力成分Q
Q_nb = calc_Q_nominal_brace(com, rs_analysis0, cxl, cyl);

% 各名目ブレースが跨ぐ階（多層ブレースの水平力を跨ぐ各階に計上する
% ため、βおよび水平力分担表 writer が共通参照する）
brace_in_story = calc_brace_story_membership(com);

% 水平力分担表相当の階別・フレーム別集計（柱座屈長さ補正βと水平力
% 分担表出力が共通参照する正本）。出力でも使うため制約評価の外で生成
frame_shear_ratio = calc_frame_shear_ratio(com, rs_analysis0, cxl, cyl, ...
  Q_nb, brace_in_story);

%% 許容応力度比制約
if coptions.consider_stress_ratio
  % ブレース水平力分担率の算出（出力階解決後の [story×lc]）
  beta = calc_brace_force_share_ratio(frame_shear_ratio);

  % ブレース・柱の座屈長さ用部材長を算出
  % ブレース分は analysis_frame で算出済みの lmem.buckling を流用
  lm_bk_x = lm;
  lm_bk_y = lm;
  lm_bk_x(mtype==PRM.BRACE) = lmem.buckling(mtype==PRM.BRACE);
  lm_bk_y(mtype==PRM.BRACE) = lmem.buckling(mtype==PRM.BRACE);
  if options.column_member_length_type == 1
    % 柱剛性表と同じ剛域長さを端部控除に使う
    lm_bk_x(mtype==PRM.COLUMN) = calc_column_buckling_segment_length( ...
      com.nominal.column, lm(mtype==PRM.COLUMN), lr.columnx);
    lm_bk_y(mtype==PRM.COLUMN) = calc_column_buckling_segment_length( ...
      com.nominal.column, lm(mtype==PRM.COLUMN), lr.columny);
  end

  % 許容応力度比計算
  if options.consider_web_at_girder_center
    Zyc = msprop.Zy;
  else
    Zyc = msprop.Zyf;
  end
  [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij, fcn, fbn, ...
    fsn, ftn, kcx, kcy, lkx, lky, ration, bkinfo, id_center_sel, ...
    girderSectionAxialMask, fbn_by_fb1, nomgc] = ...
    eval_nominal_allowable_stress_ratio(msdim, stn, stcn, A, Iy, Iz, ...
    Zyc, C, mtype, mstype, isxdir_member, isydir_member, ...
    wgx, wgy, Em, Fm, idm2n, lb, lm, lm_bk_x, lm_bk_y, lnm, ...
    mejoint, nominal, isgmirrored, idmg2mng, idmc2mnc, options, ...
    beta, lcdir, idmc2st, com.member.column.onfg_x, ...
    com.member.column.onfg_y, Cn, nomgc, com.column_buckling_K);

  % S梁断面算定表の表示用採用ケース
  tiebreak = zeros(1, size(gri, 2));
  tiebreak(PRM.LT) = eps;
  tiebreak(PRM.EXP) = eps;
  tiebreak(PRM.EYP) = eps;
  [~, girderSectionCase.ilc] = max(gri + tiebreak, [], 2);
  [~, girderSectionCase.clc] = max(grc + tiebreak, [], 2);
  [~, girderSectionCase.jlc] = max(grj + tiebreak, [], 2);

  % S梁断面算定表の軸力検定表示有無
  inm = nominal.girder.idnominal(:);
  ilc = girderSectionCase.ilc(:);
  clc = girderSectionCase.clc(:);
  jlc = girderSectionCase.jlc(:);
  sz = size(girderSectionAxialMask.i);
  has_i = girderSectionAxialMask.i(sub2ind(sz, inm, ilc));
  has_c = girderSectionAxialMask.c(sub2ind(sz, inm, clc));
  has_j = girderSectionAxialMask.j(sub2ind(sz, inm, jlc));
  girderSectionHasAxial = has_i | has_c | has_j;

  % 正確な細長比を算出
  [lambday, lambdaz] = calc_lambda(A, Iy, Iz, mtype, mstype, lkx, lky);

  gr = max([reshape([gri; grj; grc],nng,[])],[],2) ...
    +coptions.alfa_stress_ratio;
  gs = max([reshape([gsi; gsj],nng,[])],[],2) + coptions.alfa_stress_ratio;
  cr = max([reshape([cri; crj],nnc,[])],[],2) + coptions.alfa_stress_ratio;
  cs = max([reshape([csi; csj],nnc,[])],[],2) + coptions.alfa_stress_ratio;
  bn = max(bnij,[],2)+coptions.alfa_stress_ratio;
else
  lm_bk_x = lm;
  lm_bk_y = lm;
  beta = [];
  gri = []; grj = []; grc = [];
  cri = []; crj = [];
  gsi = []; gsj = [];
  csi = []; csj = []; bnij = [];
  fcn = []; fbn = []; fsn = [];
  fbn_by_fb1 = [];
  kcx = []; kcy = [];
  lkx = lm; lky = [lm lm lm];
  lambday = []; lambdaz = []; ration = [];
  bkinfo = []; id_center_sel = [];
  girderSectionCase.ilc = [];
  girderSectionCase.clc = [];
  girderSectionCase.jlc = [];
  girderSectionAxialMask.i = [];
  girderSectionAxialMask.c = [];
  girderSectionAxialMask.j = [];
  girderSectionHasAxial = [];
  gr = []; gs = []; cr = []; cs = []; bn = [];

end

%% 層間変形角制約
if coptions.consider_inter_story
  [condrift, drift_angle, drift_idcolumn, drift_dx, drift_dy, ...
    drift_height, drift_delta_x, drift_delta_y] = ...
    eval_interstory_drift(dnode, column_floor_height, ...
    lcdir, dmax, idfl2s, idmc2st, idc2n, idn2st, ...
    com.floor.standard_height, options);
  condrift = condrift+coptions.alfa_inter_story;
else
  condrift = [];
  drift_angle = [];
  drift_idcolumn = [];
  drift_dx = [];
  drift_dy = [];
  drift_height = [];
  drift_delta_x = [];
  drift_delta_y = [];
end

%% 梁中央たわみ制約（名目梁単位）
if coptions.consider_girder_deflection
  idmeg_ = nominal.girder.idmeg;
  gstype_ = com.member.girder.section_type;
  Iyd = msprop.Iy;
  Iyd(idmg2m) = Iyd(idmg2m) .* gphiI;
  [congdef, gdef_angle] = calc_nominal_girder_deflection( ...
    idmeg_, idmg2m, gstype_, lm, lf, rs, M0sw, Em, Iyd, ...
    gdmax);
  congdef = congdef + coptions.alfa_girder_deflection;
else
  congdef = [];
  gdef_angle = [];
end

%% 幅厚比制約
if coptions.consider_section_wt_ratio
  [conwtg, conwtc, wtratio] = calc_wtratio(secdim, Fs, ...
    idsrep2s, idsrep2stype, grank, crank, isSNsec, options);
  conwtg = conwtg+coptions.alfa_section_wt_ratio;
  conwtc = conwtc+coptions.alfa_section_wt_ratio;
else
  conwtg = []; conwtc = []; wtratio = [];
end

%% 細長比（保有耐力横補剛）制約
if coptions.consider_slenderness_ratio
  lbwfs = lb(idmwfs2m,:);
  lmwfs = lnm(idmwfs2m);
  [conslr, slratio] = calc_girder_stiffening(msdimwfs, ...
    Ag, Izg, Zyg, Zpyg, lbwfs, lmwfs, Fg, slr);
  conslr = conslr+coptions.alfa_slenderness_ratio;
else
  lbwfs = [];
  lmwfs = [];
  conslr = [];
  slratio = [];
end

%% 保有耐力接合（仕口）制約（名目梁単位）
if coptions.consider_joint_bearing_strength
  [conjbs, jbsratio, idjbs] = calc_joint_bearing_strength( ...
    secdim, Zpy, Fm, msprop.steel_grade, com, options);
else
  conjbs = [];
  jbsratio = [];
  idjbs = [];
end

%% 柱梁耐力比制約
% 帳票出力用に常時計算し、制約への組込みのみオプションに従う
[concgsr, cgsr] = calc_cgstrength_ratio(Zpy, vix, viy, idncgsr, ...
  idm2n, idmc2m, mtype, Fm, cxl, isxdir_member, isydir_member, ...
  com.cgsr.istarget);
if coptions.consider_joint_strength_ratio
  concgsr = concgsr+coptions.alfa_joint_strength_ratio;
else
  concgsr = [];
end

%% 規格サイズに関する制約
if coptions.consider_standard_section_list
  congapstd = calc_section_list_gap(secdim, secmgr);
else
  congapstd = [];
end

%% 梁せいの差制約（呼称寸法）
if coptions.consider_girder_height_gap_var
  conhgapvar = calc_girder_height_gap_var(xvar, idvarHgap, options);
else
  conhgapvar = [];
end

%% 梁せいの差制約（実寸）
if coptions.consider_girder_height_gap_section
  conhgapsec = calc_girder_height_gap_section(secdim, idsecHgap, options);
else
  conhgapsec = [];
end

%% 柱外径の差制約（呼称寸法）
if coptions.consider_column_diameter_gap
  condgapvar = calc_column_diameter_gap_var(xvar, idvarDgap, options);
else
  condgapvar = [];
end

%% 梁せい分布平滑化制約
if coptions.consider_girder_height_smooth_var
  conhsmoothvar = calc_girder_height_smooth_var(xvar, ...
    height_smooth, options);
else
  conhsmoothvar = [];
end

%% 制約値ベクトルの集約
cvec = [gr; gs; cr; cs; bn; congdef; conwtg; conwtc; ...
  conslr; conjbs; condrift; concgsr; congapstd; ...
  conhgapvar; conhgapsec; condgapvar; conhsmoothvar]';
if nargout<2
  return
end

%% 出力引数に応じた結果の設定
if nargout==3
  restoration.slratio = slratio;
  restoration.C = C;
  restoration.vix = vix;
  restoration.viy = viy;
  restoration.lbwfs = lbwfs;
  restoration.lmwfs = lmwfs;
  restoration.slr = slr;

  result.secdim = secdim;
  result.cxl = cxl;
  result.cyl = cyl;
  result.Q_nb = Q_nb;
  result.frame_shear_ratio = frame_shear_ratio;
  return
end
result.ncon = [length(gr) length(gs) length(cr) ...
  length(cs) length(bn) length(congdef) ...
  length(conwtg) length(conwtc) length(conslr) ...
  length(conjbs) length(condrift) length(concgsr) ...
  length(congapstd) length(conhgapvar) ...
  length(conhgapsec) length(condgapvar) length(conhsmoothvar)];
result.conlabel = {'梁曲げ応力', '梁せん断応力', '柱曲げ応力', ...
  '柱せん断応力', 'ブレース応力', '梁たわみ', '梁幅厚比', ...
  '柱幅厚比', '保有耐力横補剛', '保有耐力接合(仕口)', ...
  '層間変形', '柱梁耐力比', '断面規格', '梁せい差-呼称', ...
  '梁せい差-寸法', '柱外径', '梁せい分布'};
result.gri = gri;
result.grj = grj;
result.grc = grc;
result.cri = cri;
result.crj = crj;
result.gsi = gsi;
result.gsj = gsj;
result.csi = csi;
result.csj = csj;
result.bnij = bnij;
result.form = congdef;
result.wid_thick = conwtg;
result.wid_c = conwtc;
result.fr = conslr;
result.deflect = condrift;
result.concgsr = concgsr;
result.rps = cgsr;
result.A = A;
result.Iy = Iy;
result.Iz = Iz;
result.msprop = msprop;
result.cphiI = cphiI;
result.gphiI = gphiI;
result.gphiAs = gphiAs;
result.gphiAn = gphiAn;
result.drift.angle = drift_angle;
result.drift.idcolumn = drift_idcolumn;
result.drift.dx = drift_dx;
result.drift.dy = drift_dy;
result.drift.height = drift_height;
result.drift.delta_x = drift_delta_x;
result.drift.delta_y = drift_delta_y;
result.deflection_angle = gdef_angle;
result.wtratio = wtratio;
if ~isempty(wtratio)
  result.rank.section = wtratio.drank_sec;
end
result.standardGap_gc = congapstd;
result.Hgapval = conhgapvar;
result.Hgapsec = conhgapsec;
result.rs = rs;
result.rs0 = rs0;
result.rs_analysis0 = rs_analysis0;
result.beta = beta;
result.Q_nb = Q_nb;
result.frame_shear_ratio = frame_shear_ratio;
result.Mc = Mc;
result.Mc0 = Mc0;
result.dfn = dfn;
result.dfn0 = dfn0;
result.stn = stn;
result.stcn = stcn;
result.fbn = fbn;
result.fbnByFb1 = fbn_by_fb1;
result.fcn = fcn;
result.fsn = fsn;
result.ftn = ftn;
result.kcx = kcx;
result.kcy = kcy;
result.bkinfo = bkinfo;
if isfield(bkinfo, 'lbc_nominal')
  result.lbc_nominal = bkinfo.lbc_nominal;
else
  result.lbc_nominal = struct('x', [], 'y', [], 'bk', ...
    struct('x', [], 'y', []));
end
result.lambday = lambday;
result.lambdaz = lambdaz;
result.ration = ration;
result.dvec = dvec;
result.dnode = dnode;
result.rvec = rvec;
result.rvec0 = rvec0;
result.secdim = secdim;
result.C = C;
result.vix = vix;
result.viy = viy;
result.cgsr = cgsr;
result.sw = sw;
result.lb = lb;
result.lf = lf;
result.lr = lr;
result.lm = lm;
% ブレース部はSS7マニュアル3.8.1の内法長さ（座屈長算定用）
result.lm_buckling = lmem.buckling;
result.lkx = lkx;
result.lky = lky;
result.lm_weight = lm_weight;
result.lm_nominal = lnm;
lm_bk_nom_x = lm_bk_x;
lm_bk_nom_y = lm_bk_y;
lm_bk_nom_x(mtype==PRM.COLUMN) = calc_nominal_column_length( ...
  com.nominal.column, lm_bk_x(mtype==PRM.COLUMN));
lm_bk_nom_y(mtype==PRM.COLUMN) = calc_nominal_column_length( ...
  com.nominal.column, lm_bk_y(mtype==PRM.COLUMN));
result.lm_bk_nominal = lm_bk_nom_x;
result.lm_bk_nominal_x = lm_bk_nom_x;
result.lm_bk_nominal_y = lm_bk_nom_y;
result.cbs = cbs;
result.baseline = baseline;
result.node = node;
result.floor = floor;
result.story = story;
result.slratio = slratio;
result.conslr = conslr;
result.jbsratio = jbsratio;
result.idjbs = idjbs;
result.cxl = cxl;
result.cyl = cyl;
result.felement = felement;
result.state = state;
result.id_center_sel = id_center_sel;
result.girderSectionCase = girderSectionCase;
result.girderSectionAxialMask = girderSectionAxialMask;
result.girderSectionHasAxial = girderSectionHasAxial;
result.nomgc = nomgc;
return
end

