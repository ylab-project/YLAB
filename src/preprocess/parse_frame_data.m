function com = parse_frame_data(com, options)
%parse_frame_data - 読込済み入力から荷重割当の基準モデルを構築する
%
%   com = parse_frame_data(com, options) は、節点を同一化して入力柱を
%   保存し、固定した断面・変数対応と断面管理を一度だけ生成する。
%   入力の設計変数値と仮定断面から初期値を設定し、解析部材を確定する。
%
%   入力引数:
%     com     - 読込・正規化した架構、断面、材料、計算条件
%     options - 断面選択と解析モデルの設定
%
%   出力引数:
%     com - 荷重の作用先を割り当てられる初期解析モデル

%% 節点同一化: 部材の節点番号を代表節点に置換
[idnode1, idnode2] = countup_node_with_representative(com);
com.member.property.idnode1 = idnode1;
com.member.property.idnode2 = idnode2;
com.member.girder.idnode1 = idnode1(com.member.girder.idme);
com.member.girder.idnode2 = idnode2(com.member.girder.idme);
com.member.column.idnode1 = idnode1(com.member.column.idme);
com.member.column.idnode2 = idnode2(com.member.column.idme);
com.member.brace.idnode1 = idnode1(com.member.brace.idme);
com.member.brace.idnode2 = idnode2(com.member.brace.idme);
com.member.horizontal_brace.idnode1 = ...
  idnode1(com.member.horizontal_brace.idme);
com.member.horizontal_brace.idnode2 = ...
  idnode2(com.member.horizontal_brace.idme);

%% 入力柱の保持
% 入力柱の端点と端部指定は分割後の部材から復元しない。
mc = com.member.column;
com.member.column_input = struct('idnode1', mc.idnode1, ...
  'idnode2', mc.idnode2, 'idz', mc.idz, 'isthrough', mc.isthrough, ...
  'idconnected', mc.idconnected, 'joint', mc.joint);

%% 設計変数と代表断面
% 設計変数と代表断面は入力定義から一度だけ生成する。
[com.design.idsec, com.design.variable.type, ...
  com.design.variable.idpvar] = set_idvar_to_design(com);
com.section.representative = countup_srep(com);
[com.design.variable.idsrep, com.section.property.idsrep] = ...
  find_idvar2srep(com);
com.ns6 = 6 * com.nsup;

%% 初期の接続と断面の確定
% 基礎梁とブレースの接続を先に確定し、初期断面の分割判定に使う。
[com.nominal.girder, com.member.girder.idnominal] = ...
  countup_nominal_girder(com);
com.node = table2struct(com.node, 'ToScalar', true);
com.member.column = table2struct(com.member.column, 'ToScalar', true);
com.member.girder = table2struct(com.member.girder, 'ToScalar', true);
% 断面の列配列も反復評価へ渡す構造体へ一度だけ変換する。
com.section.column = table2struct(com.section.column, 'ToScalar', true);
com.section.girder = table2struct(com.section.girder, 'ToScalar', true);
com = update_frame_topology(com);
[com.story.idvar_girder, com.story.nvar_girder] = ...
  countup_idvar_each_story(com);
com.section.girder.rank = exclude_girder_stress(com);
com.section.column.rank = exclude_column_stress(com);
[com.gapjoint, com.Hgap.idsec, com.Hgap.idvar] = ...
  countup_girder_gapjoint(com);
com.ngapjoint = size(com.gapjoint, 1);
com.height_smooth = create_girder_height_smooth_data(com);
com.exclusion.is_joint_bearing_strength = ...
  exclude_joint_bearing_strength(com);

%% 断面管理と初期断面
% 断面管理は入力時に一度だけ構築する。候補ごとの部材番号を保持しない。
design = com.design;
Hp = design.variable.idvar(design.variable.type == PRM.WFS_H);
Bp = design.variable.idvar(design.variable.type == PRM.WFS_B);
twp = design.variable.idvar(design.variable.type == PRM.WFS_TW);
tfp = design.variable.idvar(design.variable.type == PRM.WFS_TF);
Dp = design.variable.idvar(design.variable.type == PRM.HSS_D);
tp = design.variable.idvar(design.variable.type == PRM.HSS_T);
HsrDp = design.variable.idvar(design.variable.type == PRM.HSR_D);
Hsrtp = design.variable.idvar(design.variable.type == PRM.HSR_T);
brb1p = design.variable.idvar(design.variable.type == PRM.BRB_V1);
brb2p = design.variable.idvar(design.variable.type == PRM.BRB_V2);
com.secmgr = create_section_manager(Hp, Bp, twp, tfp, Dp, tp, ...
  HsrDp, Hsrtp, brb1p, brb2p, com, com.sectionList, options);
xini = extract_initial_design_value(com, options);
if ~isempty(xini)
  com.design.variable.value = xini(:);
end
secdim = com.secmgr.findNearestSection(com.design.variable.value, options);
com = update_frame_data(secdim, com, options);
idm2n = [com.member.property.idnode1 com.member.property.idnode2];
lm = calc_member_length_from_node(com.node, idm2n);
com.member.girder = countup_girder_stiffening(com, lm);
[com.member.girder, com.nominal.girder] = ...
  countup_girder_stiffening_direct(com, lm);

return
end


function  [idsec, vartype, idpvar] = set_idvar_to_design(com)
%set_idvar_to_design - 断面形状別の設計変数と断面番号を整理する
%
%   [idsec, vartype, idpvar] = set_idvar_to_design(com) は、
%   断面リストの鉄骨形状から寸法変数を分類する。
%
%   入力引数:
%     com - 部材・断面・断面リストを含む共通データ構造体
%
%   出力引数:
%     idsec   - 形状ごとの断面番号を持つ構造体（各値は行ベクトル）
%     vartype - 各設計変数の寸法種別 [nvar×1]
%     idpvar  - 変数種別内の番号の初期値 [nvar×1]（全要素0）

% 共通定数
nsec = com.nsec;
nvar = com.nvar;

% 共通配列
section_property = com.section.property;

% 設計変数の種別は断面が参照する断面リストの鉄骨形状で決める。梁のWFSと
% 柱のCWFS・CWFSIは同じH形鋼の寸法変数を持つ。リストなし（RC）は0
list_type = com.sectionList.section_type;
section_shape = zeros(nsec,1);
has_list = section_property.id_section_list > 0;
section_shape(has_list) = ...
  list_type(section_property.id_section_list(has_list));

% 角形鋼管の各次元の独立変数番号
ndvar = PRM.nvar_of_section_type(PRM.HSS);
idvar_ = cell(ndvar,1);
istarget = (section_shape == PRM.HSS);
for i=1:ndvar
  idvar_{i} = section_property.idvar(istarget,i);
end
idvar.hss.D = idvar_{1};
idvar.hss.t = idvar_{2};

% H形鋼の各次元の独立変数番号
ndvar = PRM.nvar_of_section_type(PRM.WFS);
idvar_ = cell(ndvar,1);
istarget = (section_shape == PRM.WFS);
for i=1:ndvar
  idvar_{i} = section_property.idvar(istarget,i);
end
idvar.wfs.H = idvar_{1};
idvar.wfs.B = idvar_{2};
idvar.wfs.tw = idvar_{3};
idvar.wfs.tf = idvar_{4};

% 座屈拘束ブレースの各次元の独立変数番号
ndvar = PRM.nvar_of_section_type(PRM.BRB);
idvar_ = cell(ndvar,1);
istarget = (section_shape == PRM.BRB);
for i=1:ndvar
  idvar_{i} = section_property.idvar(istarget,i);
end
idvar.brb.V1 = idvar_{1};
idvar.brb.V2 = idvar_{2};

% 円形鋼管（HSR）の各次元の独立変数番号
ndvar = PRM.nvar_of_section_type(PRM.HSR);
idvar_ = cell(ndvar,1);
istarget = (section_shape == PRM.HSR);
for i=1:ndvar
  idvar_{i} = section_property.idvar(istarget,i);
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
idsec.wfs = find(section_shape' == PRM.WFS);
idsec.hss = find(section_shape' == PRM.HSS);
idsec.brb = find(section_shape' == PRM.BRB);
idsec.hsr = find(section_shape' == PRM.HSR);
return
end


function [idstory2var_girder, idstory2num_var_girder] = ...
  countup_idvar_each_story(com)
%countup_idvar_each_story - 層ごとの梁の設計変数番号と個数を求める
%
%   [idstory2var_girder, idstory2num_var_girder] =
%   countup_idvar_each_story(com) は、梁の4寸法成分について層別に
%   重複しない正の設計変数番号を集める。
%
%   入力引数:
%     com - 層と梁の設計変数番号を持つ共通データ
%
%   出力引数:
%     idstory2var_girder     - 層・寸法成分別の変数番号 {nstory×4}
%     idstory2num_var_girder - 層・寸法成分別の変数個数 [nstory×4]

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


function  section_representative = countup_srep(com)
%countup_srep - 変数・指定寸法・リストが同一の断面を集約する
%
%   section_representative = countup_srep(com) は、各組合せの最初の
%   断面を代表として、断面番号・種別・変数・指定寸法を返す。
%
%   入力引数:
%     com - 統一断面情報を持つ共通データ
%
%   出力引数:
%     section_representative - 代表断面の情報を持つテーブル


% 共通定数
% nsec = com.nsec;
% nvar = com.nvar;

% 共通配列
ids2var = com.section.property.idvar;
ids2stype = com.section.property.type;
ids2dim = com.section.property.dimension;
ids2list = com.section.property.id_section_list;

% 代表断面の抜き出し
[~, idsrep2sec, ~] = unique([ids2var ids2dim ids2list], 'rows', 'stable');
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

section_representative = table(idsrep2sec, idsrep2stype, idsrep2var, ...
  ids2dim, 'VariableNames', {'idsec', 'section_type', 'idvar', ...
  'dimension'});
return
end


function  [idvar2srep, idsec2srep, idsrep2sec] = find_idvar2srep(com)
%find_idvar2srep - 設計変数・断面・代表断面の対応を求める
%
%   [idvar2srep, idsec2srep, idsrep2sec] = find_idvar2srep(com) は、
%   変数・指定寸法・リストの組合せで断面を集約し、相互の番号を返す。
%
%   入力引数:
%     com - 統一断面情報と設計変数数を持つ共通データ
%
%   出力引数:
%     idvar2srep - 各設計変数を使う代表断面番号 {nvar×1}
%     idsec2srep - 断面から代表断面への番号 [nsec×1]
%     idsrep2sec - 代表断面から断面への番号 [nsrep×1]

% 共通定数
nvar = com.nvar;

% 共通配列
ids2var = com.section.property.idvar;
ids2dim = com.section.property.dimension;
ids2list = com.section.property.id_section_list;

% 代表断面の抜き出し
[idsrep, idsrep2sec, idsec2srep] = unique([ids2var ids2dim, ids2list], ...
  'rows', 'stable');

% 変数番号 -> 代表断面番号の変換
idvar2srep = cell(length(nvar),1);
idsrep_ = idsrep(:,1:4);
for iv=1:nvar
  istarget = any(idsrep_==iv,2);
  idvar2srep{iv,1} = find(istarget)';
end

return
end
