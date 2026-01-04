function [cvec, result, restoration] = ...
  analysis_constraint(xvar, com, options)
%ANALYSIS_CONSTRAINT 構造解析と制約条件の評価
% 概要: フレーム解析を実行し、各種制約条件を評価して制約値を返す
% 構文: [cvec, result, restoration] = analysis_constraint(xvar, com, options)
% 入力:
%   xvar    - 設計変数ベクトル [nvar×1]
%   com     - 共通データ構造体
%   options - 解析オプション構造体
% 出力:
%   cvec        - 制約値ベクトル [1×ncon] (正の値が制約違反)
%   result      - 詳細結果構造体（応力、変形、諸元等）
%   restoration - 復元用データ構造体
% 備考: 評価される制約は options.coptions で制御
% See also: analysis_frame, eval_nominal_allowable_stress_ratio

% 共通定数の取得
nsec = com.nsec;                              % 断面数
nme = com.nme;                                % 部材数
nng = size(com.nominal.girder.idmeg,1);      % 名目梁数
nnc = size(com.nominal.column.idmec,1);      % 名目柱数

% ID配列の取得
idn2z = com.node.idz;                         % 節点→Z座標
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
idsrep2stype = com.section.representative.section_type; % 代表断面→断面タイプ
idstory2varH = com.story.idvarH;              % 層→梁せい変数番号

% 共通配列の取得
dmax = 200;                                    % 層間変形角の制限値（1/dmax）
gdmax = 300;                                   % 梁たわみの制限値（1/gdmax）
idvarHgap = com.Hgap.idvar;                   % 梁せい差評価用変数番号
idvarDgap = com.Dgap.idvar;                   % 柱外径差評価用変数番号
idsecHgap = com.Hgap.idsec;                   % 梁せい差評価用断面番号
lcdir = com.loadcase.dir;                     % 荷重ケースの方向
mdir = com.member.property.idir;              % 部材方向
mtype = com.member.property.type;             % 部材タイプ
mstype = com.member.property.section_type;    % 部材断面タイプ
idme2stype = com.member.property.section_type; % 部材→断面タイプ
mgdir = com.member.girder.idir;               % 梁方向
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
[msprop, secdim, dvec, dnode, felement, ...
  stn, stcn, Mc, C, vix, viy, ...
  rvec, rs, dfn, rvec0, rs0, Mc0, dfn0, ~, sw, ...
  lf, lr, lm, lnm, lb, Iy, Iz, gphiI, cphiI, ...
  cbs, baseline, node, story, floor] = ...
  analysis_frame(xvar, com, options);

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
grank = com.section.girder.rank;             % 梁断面ランク

% フェイス長の計算（梁端部剛域を除く）
lmf = lm;
lmf(idmwfs2m) = lm(idmwfs2m)-sum(lf.girder(mstype==PRM.WFS,:),2);

% H形梁の断面諸元を取得
Ag = A(idmwfs2m);                            % 断面積
Iyg = Iy(idmwfs2m);                          % 断面二次モーメント（Y軸）
Izg = Iz(idmwfs2m);                          % 断面二次モーメント（Z軸）
Zyg = Zy(idmwfs2m);                          % 弾性断面係数（Y軸）
Zpyg = Zpy(idmwfs2m);                        % 塑性断面係数（Y軸）
lg = lmf(idmwfs2m);                          % フェイス長
Eg = Em(idmwfs2m);                           % ヤング率
Fg = Fm(idmwfs2m);                           % 基準強度

% 梁たわみ計算用のモーメント
M0g = M0+sw.M0;                              % 付加曲げ＋自重モーメント
M0g = M0g(idmwfs2m,1);                       % H形梁のみ抽出
Mcg = -rs(idmwfs2m,5,1)+rs(idmwfs2m,11,1);  % 梁端モーメント差

% H形鋼の断面寸法（H×B×tw×tf）
msdim = secdim(idm2s,1:4);
msdimwfs = msdim(idme2stype==PRM.WFS,:);

% 階高データ
column_floor_height = com.member.column.floor_height;

% 梁端部の結合条件の設定
gjoint = com.member.girder.joint;            % 梁の結合条件
mejoint = PRM.FIX*ones(nme,4);              % 全部材を固定で初期化
mejoint(idmg2m,:) = gjoint;                  % 梁の結合条件を設定
isgmirrored = com.member.girder.ismirrored;  % 梁の左右反転フラグ

%% 許容応力度比制約
if coptions.consider_stress_ratio
  [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij, ...
    fcn, fbn, fsn, kcx, kcy, lambday, lambdaz, ration] = ...
    eval_nominal_allowable_stress_ratio(...
    msdimwfs, stn, stcn, A, Iy, Iz, C, ...
    mtype, mstype, mgdir, Em, Fm, idm2n, lb, lnm, lr, ...
    mejoint, nominal, isgmirrored, idmg2mng, idmc2mnc, options);
  gr = max([reshape([gri; grj; grc],nng,[])],[],2) ...
    +coptions.alfa_stress_ratio;
  gs = max([reshape([gsi; gsj],nng,[])],[],2) ...
    +coptions.alfa_stress_ratio;
  cr = max([reshape([cri; crj],nnc,[])],[],2) ...
    +coptions.alfa_stress_ratio;
  cs = max([reshape([csi; csj],nnc,[])],[],2) ...
    +coptions.alfa_stress_ratio;
  bn = max(bnij,[],2)+coptions.alfa_stress_ratio;
else
  gri = []; grj = []; grc = [];
  cri = []; crj = [];
  gsi = []; gsj = [];
  csi = []; csj = []; bnij = [];
  fcn = []; fbn = []; fsn = [];
  kcx = []; kcy = []; lambday = []; lambdaz = []; ration = [];
  gr = []; gs = []; cr = []; cs = []; bn = [];

end

%% 層間変形角制約
if coptions.consider_inter_story
  [condrift, drift_angle, drift_idcolumn, drift_dx, drift_dy] = ...
    eval_interstory_drift(...
    dnode, column_floor_height, lcdir, dmax, idfl2s, idmc2st, idc2n, ...
    idn2z, options);
  condrift = condrift+coptions.alfa_inter_story;
else
  condrift = [];
  drift_angle = [];
  drift_idcolumn = [];
  drift_dx = [];
  drift_dy = [];
end

%% 梁中央たわみ制約
if coptions.consider_girder_deflection
  [congdef, gdef_angle] = ...
    calc_girder_deflection(Eg, lg, M0g, Mcg, Iyg, gdmax);
  congdef = congdef+coptions.alfa_girder_deflection;
else
  congdef = [];
  gdef_angle = [];
end

%% 幅厚比制約
if coptions.consider_section_wt_ratio
  [conwtg, conwtc, wtratio] = ...
    calc_wtratio(secdim, Fs, idsrep2s, idsrep2stype, grank, isSNsec, options);
  conwtg = conwtg+coptions.alfa_section_wt_ratio;
  conwtc = conwtc+coptions.alfa_section_wt_ratio;
else
  conwtg = []; conwtc = []; wtratio = [];
end

%% 細長比（保有耐力横補剛）制約
if coptions.consider_slenderness_ratio
  lbwfs = lb(idmwfs2m,:);
  lmwfs = lnm(idmwfs2m);
  % jointwfs = mejoint(idmwfs2m,:);
  % igthrough = com.member.girder_through.idmeg;
  % lbn = nominal.property.lb;
  [conslr, slratio] = calc_girder_stiffening(...
    msdimwfs, Ag, Izg, Zyg, Zpyg, lbwfs, lmwfs, Fg, slr);
  conslr = conslr+coptions.alfa_slenderness_ratio;
else
  lbwfs = [];
  lmwfs = [];
  conslr = [];
  slratio = [];
end

%% 保有耐力接合（仕口）制約
if coptions.consider_joint_bearing_strength
  isjbs = com.exclusion.is_joint_bearing_strength;
  [conjbs, jbsratio] = calc_joint_bearing_strength(...
    msdimwfs, Zpyg, Fg, isjbs, options);
else
  conjbs = [];
  jbsratio = [];
end

%% 柱梁耐力比制約
if coptions.consider_joint_strength_ratio
  cxl = com.member.property.cxl;
  [concgsr, cgsr] = calc_cgstrength_ratio(...
    Zpy, vix, viy, idncgsr, idm2n, idmc2m, mdir, mtype, Fm, cxl);
  concgsr = concgsr+coptions.alfa_joint_strength_ratio;
else
  concgsr = [];
  cgsr = [];
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
  conhsmoothvar = calc_girder_height_smooth_var(xvar, idstory2varH, options);
else
  conhsmoothvar = [];
end

%% 制約値ベクトルの集約
cvec = [...
  gr; gs; cr; cs; bn; ...
  congdef; ...
  conwtg; conwtc; ...
  conslr; ...
  conjbs; ...
  condrift; ...
  concgsr; ...
  congapstd; ...
  conhgapvar; ...
  conhgapsec; ...
  condgapvar; ...
  conhsmoothvar]';
if nargout<2
  return
end

%% 出力引数に応じた結果の設定
if nargout==3
  restoration.slratio = slratio;
  % restoration.st = st;
  % restoration.stc = stc;
  restoration.C = C;
  restoration.vix = vix;
  restoration.viy = viy;
  restoration.lbwfs = lbwfs;
  restoration.lmwfs = lmwfs;
  restoration.slr = slr;

  % とりあえず
  result = [];
  return
end
result.ncon = [...
  length(gr) length(gs) length(cr) length(cs) length(bn)...
  length(congdef) ...
  length(conwtg) length(conwtc) ...
  length(conslr) ...
  length(conjbs) ...
  length(condrift) ...
  length(concgsr) ...
  length(congapstd) ...
  length(conhgapvar) ...
  length(conhgapsec) ...
  length(condgapvar) ...
  length(conhsmoothvar)];
result.conlabel = {...
  '梁曲げ応力','梁せん断応力','柱曲げ応力','柱せん断応力', 'ブレース応力'...
  '梁たわみ','梁幅厚比', '柱幅厚比', '保有耐力横補剛','保有耐力接合(仕口)', ...
  '層間変形','柱梁耐力比', ...
  '断面規格','梁せい差-呼称','梁せい差-寸法', '柱外径', '梁せい分布'};
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
% result.wid_gl = conwtglb;
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
result.drift.angle = drift_angle;
result.drift.idcolumn = drift_idcolumn;
result.drift.dx = drift_dx;
result.drift.dy = drift_dy;
result.deflection_angle = gdef_angle;
result.wtratio = wtratio;
% result.idRpsNode = cgsr;
result.standardGap_gc = congapstd;
result.Hgapval = conhgapvar;
result.Hgapsec = conhgapsec;
result.rs = rs;
result.rs0 = rs0;
result.Mc = Mc;
result.Mc0 = Mc0;
result.dfn = dfn;
result.dfn0 = dfn0;
result.stn = stn;
result.stcn = stcn;
result.fbn = fbn;
result.fcn = fcn;
result.fsn = fsn;
result.kcx = kcx;
result.kcy = kcy;
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
result.lm_nominal = lnm; 
result.cbs = cbs;
result.baseline = baseline;
result.node = node;
result.floor = floor;
result.story = story;
result.slratio = slratio;
result.conslr = conslr;
result.jbsratio = jbsratio;
result.felement = felement;
return
end
