function com = parse_frame_data(com, options)
%  --- 新旧対応 ---
%  [定数]
%   nb -> nbw
%
%  [配列]
%   repc -> section.column.idrepc
%   repg -> section.girder.idrepg
%   lm -> member.property.lm : 部材長さ（芯間距離）
%   nstiff -> member.girder.nstiff
%   perH -> story.nvar_girder(:,1)
%   perB -> story.nvar_girder(:,2)
%   varH -> story.idvar_girder(:,1);
%   varB -> story.idvar_girder(:,2);
%   Hn -> design.variable.idpvar(design.idvar.wfs.H);
%   Bn -> design.variable.idpvar(design.idvar.wfs.B);
%   twn -> design.variable.idpvar(design.idvar.wfs.tw);
%   tfn -> design.variable.idpvar(design.idvar.wfs.tf);
%   Dn -> design.variable.idpvar(design.idvar.hss.D);
%   tn -> design.variable.idpvar(design.idvar.hss.t);
%   種別断面番号 -> 種別代表部材番号
%   repc -> section.column.idrepc;
%   repg -> section.girder.idrepg;
%   種別部材番号 -> 種別断面番号
%   repginv -> member_girder.idsecg;
%   repcinv -> member_column.idsecc;

%% 共通配列
design = com.design;
% member = com.member;
section = com.section;
section_column = com.section.column;
section_girder = com.section.girder;
section_property = com.section.property;
secList = com.sectionList;
story = com.story;
% idn2s = com.node.idstory;
% idm2s1 = com.member.property.idnode1;
% idm2s2 = com.member.property.idnode2;
% idconnected_girder = com.member.girder.idconnected_girder;
% idx_girder = com.member.girder.idx;
% idy_girder = com.member.girder.idy;
member_girder = com.member.girder;
member_column = com.member.column;
member_brace = com.member.brace;
% lgm = com.member.property.lm(com.member.girder.idme);

%% 変数配列
[design_idvar, design_idsec, design_variable_type, ...
  design_variable_idpvar] = set_idvar_to_design(com);
design.idvar = design_idvar;
design.idsec = design_idsec;
design.variable.type = design_variable_type;
design.variable.idpvar = design_variable_idpvar;
com.design = design;

%% バンド幅算定
nbw = countup_band_width(com);
com.nbw = nbw;

%% 支持条件用パラメータ
ns6 = 6*com.nsup;
com.ns6 = ns6;

%% ダミー層の処理
% nominal_story = countup_nominal_story(com);

%% 通し柱
[idnominal_column, isprimary_column, idsecc, nominal_column] = ...
  countup_nominal_column(member_column, member_girder, member_brace, com);
member_column.idnominal = idnominal_column;
member_column.isprimary = isprimary_column;
member_column.idsecc = idsecc;
idsec = com.section.column.idsec(idsecc);
com.member.column = member_column;
com.member.property.idsec(member_column.idme) = idsec;
com.member.property.idsecc(member_column.idme) = idsecc;
com.nominal.column = nominal_column;
com.num.nominal_column = nnz(idnominal_column(:,2)==1);

%% 層内梁変数の数
[idstory2var_girder, idstory2num_var_girder] = ...
  countup_idvar_each_story(com);
story.idvar_girder = idstory2var_girder;
story.nvar_girder = idstory2num_var_girder;
com.story = story;

%% 柱断面の検索
[idsecc2mec, idsecc2repc, idsecc2mem, idsecc2repm] = find_crep(com);
section_column.idmec = idsecc2mec;
section_column.idrepc = idsecc2repc;
section_column.idmem = idsecc2mem;
section_column.idrepm = idsecc2repm;
section.column = section_column;
com.section = section;

%% 梁断面の検索
[idsecg2meg, idsecg2repg, idsecg2mem, idsecg2repm] = find_repg(com);
section_girder.idmeg = idsecg2meg;
section_girder.idrepg = idsecg2repg;
section_girder.idmem = idsecg2mem;
section_girder.idrepm = idsecg2repm;
section.girder = section_girder;
com.section = section;

%% 代表断面
section_representative = countup_srep(com);
section.representative = section_representative;
com.section = section;

%% 変数と代表断面の関係検索
[idvar2srep, idsec2srep] = find_idvar2srep(com);
section_property.idsrep = idsec2srep;
section.property = section_property;
com.section = section;
design.variable.idsrep = idvar2srep;
com.design = design;

%% 通し梁
[nominal_girder, idnominal_girder] = countup_nominal_girder(com);
lgm = com.member.property.lm(com.member.girder.idme);
lgm_nominal = calc_nominal_girder_length(nominal_girder, lgm);
com.nominal.girder = nominal_girder;
com.member.girder.idnominal = idnominal_girder;
com.member.girder.lm = lgm;
com.member.girder.lm_nominal = lgm_nominal;
com.num.nominal_girder = size(nominal_girder,1);

%% 名目ブレース
[nominal_brace, idnominal_brace] = countup_nominal_brace(com);
com.nominal.brace = nominal_brace;
com.num.nominal_brace = size(nominal_brace,1);
com.member.brace.idnominal = idnominal_brace;

%% 一本部材
[nominal_property, idnominal_girder, idnominal_column, ...
  idnominal_brace, idnominal] = countup_nominal_property(com);
com.nominal.property = nominal_property;
com.num.nominal_member = size(nominal_property,1);
nominal_girder.idnominal = idnominal_girder;
com.nominal.girder = nominal_girder;
nominal_column.idnominal = idnominal_column;
com.nominal.column = nominal_column;
nominal_brace.idnominal = idnominal_brace;
com.nominal.brace = nominal_brace;
com.member.property.idnominal = idnominal;

%% 補剛数
com.member.girder = countup_girder_stiffening(com);
com.member.girder = countup_girder_stiffening_direct(com);

% TODO:とりあえず
Hp = design.variable.idvar(design.variable.type==PRM.WFS_H);
Bp = design.variable.idvar(design.variable.type==PRM.WFS_B);
twp = design.variable.idvar(design.variable.type==PRM.WFS_TW);
tfp = design.variable.idvar(design.variable.type==PRM.WFS_TF);
Dp = design.variable.idvar(design.variable.type==PRM.HSS_D);
tp = design.variable.idvar(design.variable.type==PRM.HSS_T);
HsrDp = design.variable.idvar(design.variable.type==PRM.HSR_D);
Hsrtp = design.variable.idvar(design.variable.type==PRM.HSR_T);
brb1p = design.variable.idvar(design.variable.type==PRM.BRB_V1);
brb2p = design.variable.idvar(design.variable.type==PRM.BRB_V2);

%% 柱面番号の数え上げ
[idmeg2secl, idmeg2secr]  = countup_girder_to_column_face(com);
com.member.girder.idsec_facel = idmeg2secl;
com.member.girder.idsec_facer = idmeg2secr;

%% 梁面番号の数え上げ
[idmec2seg1x, idmec2seg1y, idmec2seg2x, idmec2seg2y, ...
  idmec2meg1x, idmec2meg1y, idmec2meg2x, idmec2meg2y] = ...
  countup_column_to_girder_face(com);
com.member.column.idsec_face1x = idmec2seg1x;
com.member.column.idsec_face1y = idmec2seg1y;
com.member.column.idsec_face2x = idmec2seg2x;
com.member.column.idsec_face2y = idmec2seg2y;
com.member.column.idmeg_face1x = idmec2meg1x;
com.member.column.idmeg_face1y = idmec2meg1y;
com.member.column.idmeg_face2x = idmec2meg2x;
com.member.column.idmeg_face2y = idmec2meg2y;

%% 各位置の階高計算
column_floor_height = countup_column_floor_height(com);
com.member.column.floor_height = column_floor_height;

%% 断面算定の省略（梁）
[isvar, girder_rank] = exclude_girder_stress(com);
% design.variable.isvar = isvar;
% com.design = design;
com.design.variable.isvar = isvar;
section_girder.rank = girder_rank;
section.girder = section_girder;
com.section = section;

%% 複数梁がとりつく節点
[gapjoint, idgapsec, idgapvar] = countup_girder_gapjoint(com);
com.gapjoint = gapjoint;
com.ngapjoint = size(gapjoint,1);
com.Hgap.idvar = idgapvar;
com.Hgap.idsec = idgapsec;

%% 柱梁耐力比の対象接合部（節点）
% 中間階の接合部数の数え上げ
% TODO 対象階の指定方法を見直しが必要
[cgsr_idnode, cgsr_idvofH, cgsr_idvofB, cgsr_idvoftw, cgsr_idvoftf, ...
  cgsr_idvofD, cgsr_idvoft]= countup_cgsr_node(com);
cgsr.idnode = cgsr_idnode;
cgsr.idvofH = cgsr_idvofH;
cgsr.idvofB = cgsr_idvofB;
cgsr.idvoftw = cgsr_idvoftw;
cgsr.idvoftf = cgsr_idvoftf;
cgsr.idvofD = cgsr_idvofD;
cgsr.idvoft = cgsr_idvoft;
com.cgsr = cgsr;
com.ncgsr = length(cgsr_idnode);

%% 断面オブジェクト
secmgr = create_section_manager(...
  Hp, Bp, twp, tfp, Dp, tp, HsrDp, Hsrtp, brb1p, brb2p, ...
  com, secList, options);
% column_base_listはcreateConstraintValidator経由で設定済み
com.secmgr = secmgr;

%% 変数初期値の設定
xini = extract_initial_design_value(com, options);
if ~isempty(xini)
  com.design.variable.value = xini(:);
else
  xini = com.design.variable.value;
end

%% 上下階関係
column_gapjoint = countup_column_gapjoint(com);
com.Dgap = column_gapjoint;
story_axis_idvarH = countup_story_axis_Hvar(com);
story.idvarH = story_axis_idvarH;
com.story = story;

% %% 上下階関係の除外指定
% exclude_story_axis_Hvar(com);

%% 保有耐力接合（仕口）の除外指定
is_joint_bearing_strength = exclude_joint_bearing_strength(com);
com.exclusion.is_joint_bearing_strength = is_joint_bearing_strength;

% 形状の更新
secdim = secmgr.findNearestSection(xini, options);
[zcoord, nodez, lm] = ...
  update_geometry_z(secdim, com.baseline, com.node, com.story, ...
  com.floor, com.section, com.member, options);
com.baseline.z.coord = zcoord;
com.node.z = nodez;
com.member.property.lm = lm;

% 補剛間隔
com.nominal.property.lb = coutup_nominal_lb(com);

% 要素数
com.num.member.girder = com.nmeg;

% テーブル変換
% TODO: 構造体に変換する
% com.material = table2struct(com.material,"ToScalar",true);
% com.story = table2struct(com.story,"ToScalar",true);
% com.floor = table2struct(com.floor,"ToScalar",true);
% com.node = table2struct(com.node,"ToScalar",true);
% com.support = table2struct(com.support,"ToScalar",true);
% com.section.column = table2struct(com.section.column,"ToScalar",true);
% com.section.girder = table2struct(com.section.girder,"ToScalar",true);
% com.section.property = table2struct(com.section.property,"ToScalar",true);
% com.section.representative = table2struct(com.section.representative,"ToScalar",true);
% com.member.column = table2struct(com.member.column,"ToScalar",true);
% com.member.girder = table2struct(com.member.girder,"ToScalar",true);
% com.section.column_base = table2struct(com.section.column_base,"ToScalar",true);
% com.member.property = table2struct(com.member.property,"ToScalar",true);
% com.loadcase = table2struct(com.loadcase,"ToScalar",true);
% com.gapjoint = table2struct(com.gapjoint,"ToScalar",true);
com.Dgap = table2struct(com.Dgap,"ToScalar",true);
% com.nominal.column = table2struct(com.nominal.column,"ToScalar",true);
% com.nominal.girder = table2struct(com.nominal.girder,"ToScalar",true);
% com.nominal.property = table2struct(com.nominal.property,"ToScalar",true);
return
end

%--------------------------------------------------------------------------
function  [idvar, idsec, vartype, idpvar] = set_idvar_to_design(com)
% 共通定数
nsec = com.nsec;
nvar = com.nvar;

% 共通配列
member_property = com.member.property;
section_property = com.section.property;

% 角形鋼管の各次元の独立変数番号
ndvar = PRM.nvar_of_section_type(PRM.HSS);
idvar_ = cell(ndvar,1);
istarget = (member_property.section_type == PRM.HSS);
for i=1:ndvar
  idvar_{i} = member_property.idvar(istarget,i);
end
idvar.hss.D = idvar_{1};
idvar.hss.t = idvar_{2};

% H形鋼の各次元の独立変数番号
ndvar = PRM.nvar_of_section_type(PRM.WFS);
idvar_ = cell(ndvar,1);
istarget = (member_property.section_type == PRM.WFS);
for i=1:ndvar
  idvar_{i} = member_property.idvar(istarget,i);
end
idvar.wfs.H = idvar_{1};
idvar.wfs.B = idvar_{2};
idvar.wfs.tw = idvar_{3};
idvar.wfs.tf = idvar_{4};

% 座屈拘束ブレースの各次元の独立変数番号
ndvar = PRM.nvar_of_section_type(PRM.BRB);
idvar_ = cell(ndvar,1);
istarget = (member_property.section_type == PRM.BRB);
for i=1:ndvar
  idvar_{i} = member_property.idvar(istarget,i);
end
idvar.brb.V1 = idvar_{1};
idvar.brb.V2 = idvar_{2};

% 円形鋼管（HSR）の各次元の独立変数番号
ndvar = PRM.nvar_of_section_type(PRM.HSR);
idvar_ = cell(ndvar,1);
istarget = (member_property.section_type == PRM.HSR);
for i=1:ndvar
  idvar_{i} = member_property.idvar(istarget,i);
end
idvar.hsr.D = idvar_{1};
idvar.hsr.t = idvar_{2};

% 変数種別
vartype = zeros(nvar,1);
for i=1:nvar
  if any(idvar.wfs.H==i)
    vartype(i) = PRM.WFS_H;
  elseif any(idvar.wfs.B==i)
    vartype(i) = PRM.WFS_B;
  elseif any(idvar.wfs.tw==i)
    vartype(i) = PRM.WFS_TW;
  elseif any(idvar.wfs.tf==i)
    vartype(i) = PRM.WFS_TF;
  elseif any(idvar.hss.D==i)
    vartype(i) = PRM.HSS_D;
  elseif any(idvar.hss.t==i)
    vartype(i) = PRM.HSS_T;
  elseif any(idvar.brb.V1==i)
    vartype(i) = PRM.BRB_V1;
  elseif any(idvar.brb.V2==i)
    vartype(i) = PRM.BRB_V2;
  elseif any(idvar.hsr.D==i)
    vartype(i) = PRM.HSR_D;
  elseif any(idvar.hsr.t==i)
    vartype(i) = PRM.HSR_T;
  end
end

% 変数種別毎の番号
idpvar = zeros(nvar,1);
% for i=1:6
%   idpvar(vartype==i) = 1:sum(+(vartype==i));
% end

% 断面番号
isss = 1:nsec;
isWFS = (section_property.type==PRM.WFS);
idsec.wfs = isss(isWFS);
isHSS = (section_property.type==PRM.HSS);
idsec.hss = isss(isHSS);
isBRB = (section_property.type==PRM.BRB);
idsec.brb = isss(isBRB);
isHSR = (section_property.type==PRM.HSR);
idsec.hsr = isss(isHSR);
return
end

%--------------------------------------------------------------------------
function  nbw = countup_band_width(com)
% 共通配列
idm2n1 = com.member.property.idnode1;
idm2n2 = com.member.property.idnode2;
node = com.node;

% 各部材の自由度番号の最大距離がバンド幅
nd1 = min([node.dof(idm2n1,:) node.dof(idm2n2,:)],[],2);
nd2 = max([node.dof(idm2n1,:) node.dof(idm2n2,:)],[],2);
nbw = max(abs(nd2-nd1))+1;
return
end

%--------------------------------------------------------------------------
function [idstory2var_girder, idstory2num_var_girder] = ...
  countup_idvar_each_story(com)
% 共通定数
nstory = com.nstory;

% 共通配列
member_girder = com.member.girder;

% 層別に梁の変数を数え上げる
idstory2var_girder = cell(nstory,4);
idstory2num_var_girder = zeros(nstory,4);
for istory=1:nstory
  for jv=1:4
    idvar = member_girder.idvar(member_girder.idstory==istory,jv);
    iddd = unique(idvar(idvar>0));
    idstory2var_girder{istory,jv} = iddd;
    idstory2num_var_girder(istory,jv) = length(iddd);
  end
end
return
end

%--------------------------------------------------------------------------
function  section_representative = countup_srep(com)

% 共通定数
% nsec = com.nsec;
% nvar = com.nvar;

% 共通配列
ids2var = com.section.property.idvar;
ids2stype = com.section.property.type;
ids2dim = com.section.property.dimension;
ids2list = com.section.property.id_section_list;

% 代表断面の抜き出し
[~, idsrep2sec, ~] = ...
  unique([ids2var ids2dim ids2list],'rows','stable');
% nsrep = length(idsrep);

% 代表断面番号 -> 変数番号
idsrep2var = ids2var(idsrep2sec,:);

% 代表断面番号 -> 断面タイプ
idsrep2stype = ids2stype(idsrep2sec);
% idsrep2hss = zeros(nsrep,1);
% idsrep2hss(idsrep2stype==PRM.HSS) = 1:
% idsrep2wfs = zeros(nsrep,1);

% 代表断面番号 -> 指定寸法
ids2dim = ids2dim(idsrep2sec,:);

section_representative = table(...
  idsrep2sec, idsrep2stype, idsrep2var, ids2dim, ...
  'VariableNames', {'idsec', 'section_type', 'idvar', 'dimension'});
return
end

%--------------------------------------------------------------------------
function [idmeg2secl, idmeg2secr] = countup_girder_to_column_face(com)
% 共通定数
nmec = com.nmec;
nmeg = com.nmeg;

% 共通配列
idmeg2n = [com.member.girder.idnode1 com.member.girder.idnode2];
idmec2n = [com.member.column.idnode1 com.member.column.idnode2];
idmec2sec = com.section.column.idsec(com.member.column.idsecc);

% 計算の準備
idmeg2secl = zeros(nmeg,2);
idmeg2secr = zeros(nmeg,2);
iccc = 1:nmec;

% 関係する変数の数え上げ
for ig = 1:nmeg
  for ilr = 1:2
    iddd = zeros(1,2);
    for idu = 1:2
      % 対象変数の特定
      idmec = iccc(any(idmec2n(:,idu)==idmeg2n(ig,ilr),2));

      % 節点の格納
      n = length(idmec);
      switch n
        case 0
        case 1
          iddd(idu) = idmec2sec(idmec);
        case 2
          error('2つ以上の梁が同一方向から柱にとりついています');
      end
    end
    switch ilr
      case 1
        idmeg2secl(ig,:) = iddd;
      case 2
        idmeg2secr(ig,:) = iddd;
    end
  end
end

return
end

%--------------------------------------------------------------------------
function [idmec2seg1x, idmec2seg1y, idmec2seg2x, idmec2seg2y, ...
  idmec2meg1x, idmec2meg1y, idmec2meg2x, idmec2meg2y] = ...
  countup_column_to_girder_face(com)
% 共通定数
nmec = com.nmec;
nmeg = com.nmeg;

% 共通配列
idmeg2n = [com.member.girder.idnode1 com.member.girder.idnode2];
idmec2n = [com.member.column.idnode1 com.member.column.idnode2];
idmeg2sec = com.section.girder.idsec(com.member.girder.idsecg);
idmeg2dir = com.member.girder.idir;

% 計算の準備
idmec2seg1x = zeros(nmec,2);
idmec2seg1y = zeros(nmec,2);
idmec2seg2x = zeros(nmec,2);
idmec2seg2y = zeros(nmec,2);

idmec2meg1x = zeros(nmec,2);
idmec2meg1y = zeros(nmec,2);
idmec2meg2x = zeros(nmec,2);
idmec2meg2y = zeros(nmec,2);
iggg = 1:nmeg;

% 関係する変数の数え上げ
for ic = 1:nmec
  for ilr = 1:2
    for idir = 1:2
      % 対象変数の特定
      idmeg = iggg(any(idmeg2n==idmec2n(ic,ilr)...
        &idmeg2dir==idir,2));

      % 節点の格納
      n = length(idmeg);
      switch n
        case 0
          iddd = zeros(1,2);
        case 1
          iddd = [idmeg2sec(idmeg) 0];
        case 2
          iddd = idmeg2sec(idmeg);
      end
      switch ilr
        case 1
          switch idir
            case PRM.X
              idmec2meg1x(ic,1:n) = idmeg(1:n);
              idmec2seg1x(ic,:) = iddd;
            case PRM.Y
              idmec2meg1y(ic,1:n) = idmeg(1:n);
              idmec2seg1y(ic,:) = iddd;
          end
        case 2
          switch idir
            case PRM.X
              idmec2meg2x(ic,1:n) = idmeg(1:n);
              idmec2seg2x(ic,:) = iddd;
            case PRM.Y
              idmec2meg2y(ic,1:n) = idmeg(1:n);
              idmec2seg2y(ic,:) = iddd;
          end
      end
    end
  end
end

return
end

%--------------------------------------------------------------------------
function [idsecc2mec, idsecc2crep, idsecc2mem, idsecc2repm] = ...
  find_crep(com)
% 共通定数
nmec = com.nmec;
nsecc = com.nsecc;
nme = com.nme;

% 共通配列
member_column = com.member.column;
member_property = com.member.property;

% 該当断面を持つ部材の数え上げ
idsecc2mec = cell(nsecc,1);
idsecc2crep = zeros(nsecc,1);
idsecc2mem = cell(nsecc,1);
idsecc2repm = zeros(nsecc,1);
iccc = 1:nmec;
immm = 1:nme;
for isecc=1:nsecc
  % 柱部材番号
  ic = iccc(member_column.idsecc==isecc);
  idsecc2mec{isecc} = ic;
  if (~isempty(ic)>0)
    idsecc2crep(isecc) = ic(1);
  end
  % 部材番号
  im = immm(member_property.idsecc==isecc);
  idsecc2mem{isecc} = im;
  if (~isempty(im)>0)
    idsecc2repm(isecc) = im(1);
  end
end

return
end

%--------------------------------------------------------------------------
function [idseg2meg, idseg2repg, idseg2mem, idseg2repm] = find_repg(com)
% 共通定数
nmeg = com.nmeg;
nsecg = com.nsecg;
nme = com.nme;

% 共通配列
member_girder = com.member.girder;
member_property = com.member.property;

% 該当断面を持つ部材の数え上げ
idseg2meg = cell(nsecg,1);
idseg2repg = zeros(nsecg,1);
idseg2mem = cell(nsecg,1);
idseg2repm = zeros(nsecg,1);
iggg = 1:nmeg;
immm = 1:nme;
for isecg=1:nsecg
  % 梁部材番号
  ig = iggg(member_girder.idsecg==isecg);
  idseg2meg{isecg} = ig;
  if (~isempty(ig)>0)
    idseg2repg(isecg) = ig(1);
  end
  % 部材番号
  im = immm(member_property.idsecg==isecg);
  idseg2mem{isecg} = im;
  if (~isempty(im)>0)
    idseg2repm(isecg) = im(1);
  end
end
return
end

%--------------------------------------------------------------------------
function  [idvar2srep, idsec2srep, idsrep2sec] = find_idvar2srep(com)
% 共通定数
nvar = com.nvar;

% 共通配列
ids2var = com.section.property.idvar;
ids2dim = com.section.property.dimension;
ids2list = com.section.property.id_section_list;

% 代表断面の抜き出し
[idsrep, idsrep2sec, idsec2srep] = ...
  unique([ids2var ids2dim, ids2list],'rows','stable');

% 変数番号 -> 代表断面番号の変換
idvar2srep = cell(length(nvar),1);
iddd = 1:length(idsrep);
idsrep_ = idsrep(:,1:4);
for iv=1:nvar
  istarget = any(idsrep_==iv,2);
  % idvar2srep{iv,1} = idsrep2sec(istarget)';
  idvar2srep{iv,1} = iddd(istarget);
end

return
end
