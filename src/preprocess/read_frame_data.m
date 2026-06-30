function [com, options] = read_frame_data(input, options)

%  --- 新旧対応 ---
%  [定数]
%   nc -> nmec  : 柱部材数
%   ndf -> ndf  : 系全体の自由度数
%   nelx, nely, nelz -> nblx, nbly, nblz : X,Y,Z通り数
%   ng -> nmeg  : 梁部材数
%   nfl -> nfl  : 階数　※層数と異なるので注意
%   nj -> nnode : 節点数
%   nlc -> nlc  : 荷重ケース数
%   nm -> nme   : 部材数
%   nsj -> nsup : 支点（節点）数
%
%  [配列]
%   ar -> ar ※(12*nlc,nm)から(nm,12,nlc)に変更
%   c_g -> member.property.type
%   compEffect -> member.girder.comp_effect
%   cxl -> member.property(column,girder).cyl : 局所x軸（材軸）の方向余弦
%   cyl -> member.property(column,girder).cyl :
%     局所y軸（断面強軸）の方向余弦
%   dirBeam -> member.girder.idir
%   E -> material.E;
%   F -> material.F;
%   f -> feqvec
%   fjnd -> 廃止 : 剛床に含まれる節点数
%   flr -> member.girder.idz or idstory
%   idme2sec -> 廃止 -> member.column.idsec, member.girder.idsec
%   idme2js(js) -> member.property(column,girder).idnode1
%   idme2je(je) -> member.property(column,girder).idnode2
%   idnode2jf(idnjf) -> node.dof
%   idsup2node(idns) -> support.idnode
%   isup -> support.isfixed ※値が反転するので注意
%   issupfixed -> support.isfixed
%   jel -> section.property.idmaterial(member.property.idsec)
%   Lb -> member.girder.Lb
%   lr -> 廃止
%   njdp -> idnode2ind : 節点番号を独立節点番号に変換
%   njsf, njef -> 廃止（層の従属自由度の開始・終了番号）
%   njr -> story.idnoderep :  剛床の代表節点番号
%   njdp -> idnode2ind : 節点番号から独立節点番号への変換
%   pd -> 廃止
%   pr -> material.pr
%   repnode -> story.idnoderep : 剛床の代表節点番号
%   SoH(1,:) -> floor.standard_heigth : 標準階高
%   SoH(2,:) -> floor.heigth : 構造階高
%   x, y, z -> node.x, node.y, node.z
%   xr, yr -> node.xr, node.yr : 重心からの距離
%
%   [部材番号から(柱/梁)部材番号を取り出したいとき]
%   idm2c = (1:nme); idm2c = idm2c(member.property.idmec>0);
%   idm2g = (1:nme); idm2g = idm2g(member.property.idmeg>0);

%% ブロック区切り
labels = {'基本事項', '構造計算条件', '最適化条件', '制約条件', ...
  '出力制御', '材料', '断面リスト', '柱脚リスト', '軸X', '軸Y', '層', ...
  'スパンX方向', 'スパンY方向', '階', '標準階高と梁心の差', ...
  '剛床仮定の解除', '節点', '支点', '部材の寄り', '柱の寄り', ...
  '大梁の寄り', '軸振れ', 'セットバック', '大梁のレベル調整', ...
  '節点の同一化', '設計変数', '梁せい分布除外', '柱外径差制限の除外', ...
  'S梁断面', 'S柱断面', 'RC梁断面', 'RC柱断面', 'メーカー製柱脚断面', ...
  '鉛直ブレース断面（鋼材）', '鉛直ブレース断面（メーカー製品）', ...
  '鉛直ブレース断面（引張ブレース）', '水平ブレース断面', ...
  'S梁断面(仮定)', 'S柱断面(仮定)', '鉛直ブレース断面（鋼材）(仮定)', ...
  '鉛直ブレース断面（メーカー製品）(仮定)', '大梁配置', '柱配置', ...
  '鉛直ブレース配置', '水平ブレース配置', '梁の結合状態', ...
  '柱の結合状態', '柱の剛域', '梁の横補剛', '柱の座屈長さ係数', ...
  '通し柱', '通し梁', 'スラブ協力幅', '柱の剛度増減率', ...
  '梁の剛度増減率', '梁の捩り剛性増減率', '柱の捩り剛性増減率', ...
  '断面算定の省略（梁符号毎）', '断面算定の省略（柱符号毎）', ...
  '荷重ケース', '節点荷重', '地震力作用位置の直接入力', ...
  '追加節点荷重', '梁要素荷重'};
dbc = data_block_class;
dbc.readCsvFile(input, labels);

%% モデル名・説明
com = struct;
com.modelname = dbc.modelname;
com.comment = dbc.comment;

%% 基本事項
options = set_basic_options_block(dbc, options);

%% 構造計算条件
options = set_analysis_options_block(dbc, options);

%% 最適化条件
options = set_optimization_options_block(dbc, options);

%% 制約条件
options.coptions = set_constraints_block(dbc, options.coptions);
if options.coptions.reqHgap>0
  options.reqHgap = options.coptions.reqHgap;
end
if options.coptions.alfa_column_diamter_gap>0
  options.tolMaxDgap = options.coptions.alfa_column_diamter_gap;
end

% 出力制御
options = set_output_options_block(dbc, options);

%% 設計変数
variable = set_variable_block(dbc);
design.variable = variable;
com.design = design;
com.nvar = max((variable.idvar));
% com.nvar = size(variable,1);

%% 材料
material = set_material_block(dbc);
com.material = material;
com.nma = size(material,1);

%% 断面リスト
section_list = set_section_list_block(dbc, input, com);
com.sectionList = section_list;
com.nsectionList = section_list.nlist;

% TB断面リストのデフォルト材料補完
TB_DEFAULT_MATERIAL = 'SN400B';
for i = 1:section_list.nlist
  if section_list.section_type(i) == PRM.TB ...
      && all(section_list.idmaterial{i} == 0)
    idm = find(matches(com.material.name, TB_DEFAULT_MATERIAL), 1);
    if isempty(idm)
      idm = com.nma + 1;
      com.material = [com.material; table(idm, {TB_DEFAULT_MATERIAL}, ...
        205000, 0.3, 79400, 235.0, true, PRM.GRADE_SN, ...
        'VariableNames', com.material.Properties.VariableNames)];
      com.nma = idm;
    end
    section_list.idmaterial{i}(:) = idm;
  end
end

%% 柱脚リスト
column_base_list = set_column_base_list_block(dbc, input, com);
com.column_base_list = column_base_list;
com.ncblist = numel(column_base_list,1);

%% 軸
xbaseline = set_xbaseline_block(dbc);
ybaseline = set_ybaseline_block(dbc);

%% 層
[story, zbaseline] = set_story_block(dbc);
com.story = story;
com.nstory = size(story,1);

%% 通り
baseline.x = xbaseline;
baseline.y = ybaseline;
baseline.z = zbaseline;
com.baseline = baseline;
com.nblx = size(baseline.x,1);
com.nbly = size(baseline.y,1);
com.nblz = size(baseline.z,1);

%% ダミー層
[nominal_story, idstory2nominal] = countup_nominal_story(com);
com.story.idnominal = idstory2nominal;
com.nominal_story = nominal_story;
com.nnominal_story = size(nominal_story,1);

%% スパン長
span.x = set_xspan_block(dbc, com);
span.y = set_yspan_block(dbc, com);
[floor, story] = set_floor_block(dbc, com);
story = set_story_diff_height_block(dbc, story);
com.span = span;
com.floor = floor;
com.story = story;
com.nfl = size(floor,1);

%% 部材の寄り
alignment = set_baseline_alignment_block(dbc, com);
baseline.xalignment = alignment.x;
baseline.yalignment = alignment.y;
baseline.alignment_column = set_baseline_alignment_column_block(dbc, com);
com.baseline = baseline;

%% 軸振れ
baseline.delta = set_baseline_delta_block(dbc, com);

%% セットバック
baseline.setback = set_baseline_setback_block(dbc, com);

%% 座標値
baseline = set_baseline_coord(baseline, span, floor, story, ...
  options, idstory2nominal);

%% 構造スパンの更新（部材の寄りを反映）
member_column = set_member_column_p1_block(dbc, com);
member.column = member_column;
com.member = member;
if options.do_autoupdate_structural_span
  [baseline.x.coord, baseline.y.coord, span.x.span, span.y.span] = ...
    update_baseline(baseline, span, member_column);
end
com.span = span;
com.baseline = baseline;

%% 節点
[node, isdummy_node] = set_node_block(dbc, com);
com.node = node;
com.nnode = size(node,1);

%% 節点の移動
[nodex, nodey] = update_xycoord(node, baseline);
node.x = nodex;
node.y = nodey;
com.node = node;

%% 節点の同一化
node = set_node_identification_block(dbc, com);
com.node = node;
com.nnode = size(node,1);

%% 支点
support = set_support_condition(dbc, com);
com.support = support;
com.nsup = size(support,1);

%% 剛床仮定の解除
flex_diaphragm = set_flexible_diaphragm(dbc, com);
com.flex_diaphragm = flex_diaphragm;
node.type(flex_diaphragm.idnode) = PRM.NODE_FLEX_DIAPHRAGM;
com.node = node;

%% S断面(梁)
[section_girder, variable] = set_section_steel_girder_block( ...
  dbc, com, options);
design.variable = variable;
com.design = design;
com.nvar = max((variable.idvar));
section.girder = section_girder;

%% S断面(柱)
[section_column, variable] = set_section_column_block(dbc, com, options);
nvrows = sum(~isnan(variable.isvar));
variable = variable(1:nvrows,:);
design.variable = variable;
com.design = design;
com.nvar = max((variable.idvar));
section.column = section_column;

%% RC断面(梁)
section_rc_girder = set_section_rc_girder_block(dbc, com);
if ~isempty(section_rc_girder)
  section_girder = [section_girder; section_rc_girder];
end
section.girder = section_girder;

%% RC断面(柱)
section_rc_column = set_section_column_rc_block(dbc, com);
if ~isempty(section_rc_column)
  section_column = [section_column; section_rc_column];
  section.column = section_column;
end
com.section = section;

%% ブレース断面
% メーカー製品
[section_brace, variable] = ...
  set_section_vertical_brace_manufacturer_block(dbc, com);
nvrows = sum(~isnan(variable.isvar));
variable = variable(1:nvrows,:);
design.variable = variable;
com.design = design;
com.nvar = max((variable.idvar));

% 鋼材断面（新規追加）
[section_brace_steel, variable_steel] = ...
  set_section_vertical_brace_steel_block(dbc, com);
if ~isempty(section_brace_steel)
  % 変数の統合
  nvrows_steel = sum(~isnan(variable_steel.isvar));
  if nvrows_steel > nvrows
    variable = variable_steel(1:nvrows_steel,:);
    design.variable = variable;
    com.design = design;
    com.nvar = max((variable.idvar));
  end
  % 断面の統合
  section_brace = [section_brace; section_brace_steel];
end

% 引張ブレース断面
section_brace_tension = set_section_vertical_brace_tension_block(dbc, com);
if ~isempty(section_brace_tension)
  section_brace = [section_brace; section_brace_tension];
end
section.brace = section_brace;

%% 水平ブレース断面
section_horizontal_brace = set_section_horizontal_brace_block(dbc, com);
section.horizontal_brace = section_horizontal_brace;
% section.brace = [section_brace; section_horizontal_brace];

%% 断面テーブルの保存
com.section = section;
com.nsecc = size(section_column,1);
com.nsecg = size(section_girder,1);
com.nsecb = size(section_brace,1);
com.nsechb = size(section_horizontal_brace,1);
com.nsec = com.nsecc+com.nsecg+com.nsecb+com.nsechb;

%% S断面(共通)
[section_property, idsecc2sec, idsecg2sec, idsecb2sec, idsechb2sec] = ...
  set_section_property(com);
section_column.idsec = idsecc2sec;
section_girder.idsec = idsecg2sec;
section_brace.idsec = idsecb2sec;
section_horizontal_brace.idsec = idsechb2sec;
section.property = section_property;
section.column = section_column;
section.girder = section_girder;
section.brace = section_brace;
section.horizontal_brace = section_horizontal_brace;
com.section = section;

%% 初期断面
initial_section_girder = set_initial_section_steel_girder_block(dbc, com);
initial_section_column = set_initial_section_column_block(dbc, com);
initial_section_brace_manufacturer  = ...
  set_initial_section_brace_manufacturer_block(dbc, com);
initial.girder = initial_section_girder;
initial.column = initial_section_column;

% 鉛直ブレース断面（メーカー製品）(仮定)から初期値を設定
initial.brace = initial_section_brace_manufacturer;
section.initial = initial;
com.section = section;

% 鉛直ブレース断面（鋼材）(仮定)から初期値を設定
[section.brace, initial_section_brace_steel] = ...
  set_initial_section_brace_steel_block(dbc, com);
% initial.braceにHSR断面も含める
if ~isempty(initial_section_brace_steel)
  if isempty(initial.brace)
    initial.brace = initial_section_brace_steel;
  else
    initial.brace = [initial.brace; initial_section_brace_steel];
  end
end
section.initial = initial;
com.section = section;

%% 部材(柱梁別)
member_girder = set_member_girder_block(dbc, com);
member.girder = member_girder;
com.member = member;
com.nmeg = size(member_girder, 1);
girder_level = set_member_girder_level_block(dbc, com);
member_girder.level = girder_level;
member.girder = member_girder;
member_column = set_member_column_p2_block(dbc, com, isdummy_node);
member.column = member_column;
com.member = member;
[member_brace, baseline, node, member_column, member_girder] = ...
  set_member_brace_block(dbc, com, options);
member.girder = member_girder;
member.column = member_column;
member.brace = member_brace;
com.member = member;
com.baseline = baseline;
com.node = node;
member_horizontal_brace = set_member_horizontal_brace_block( ...
  dbc, com, options);
member.horizontal_brace = member_horizontal_brace;
com.member = member;
member.girder = member_girder;
member.column = member_column;
member.brace = member_brace;
member.horizontal_brace = member_horizontal_brace;
com.member = member;
com.node = node;
com.baseline = baseline;
com.nmeg = size(member_girder,1);
com.nmec = size(member_column,1);
com.nmeb = size(member_brace,1);
com.nmehb = size(member_horizontal_brace,1);
com.nme = com.nmec+com.nmeg+com.nmeb+com.nmehb;
com.nnode = size(node,1);
com.nblz = size(baseline.z,1);

%% 定数
com.num.member_brace = size(member_brace,1);
com.num.member_horizontal_brace = size(member_horizontal_brace,1);

%% 部材(共通)
[member_property, idmec2mem, idmeg2mem, idmeb2mem, idmehb2mem] = ...
  set_member_property(com);
member_girder.idme = idmeg2mem;
member_column.idme = idmec2mem;
member_brace.idme = idmeb2mem;
member_horizontal_brace.idme = idmehb2mem;

% HSS柱部材番号の設定
nmec = size(member_column,1);
idmehss = zeros(nmec,1);
section_type_c = member_property.section_type(idmec2mem);
is_hss = (section_type_c == PRM.HSS);
idmehss(is_hss) = 1:sum(is_hss);
member_column.idmehss = idmehss;

member.property = member_property;
member.column = member_column;
member.girder = member_girder;
member.brace = member_brace;
member.horizontal_brace = member_horizontal_brace;
com.member = member;

%% 大梁のレベル調整
girder_level = set_member_girder_level_block(dbc, com);
member_girder.level = girder_level;
member.girder = member_girder;
com.member = member;

%% 梁の結合状態
member_girder_joint = set_member_girder_joint_block(dbc, com);
member_girder.joint = member_girder_joint;
member.girder = member_girder;
com.member = member;

%% 柱の結合状態
member_column_joint = set_member_column_joint_block(dbc, com);
member_column.joint = member_column_joint;
member.column = member_column;
com.member = member;

%% 柱の剛域（直接入力）
member_column_rigid_zone = set_member_column_rigid_zone_block(dbc, com);
member.column_rigid_zone_direct = member_column_rigid_zone;
com.member = member;

%% 通し梁
[isthrough_girder, idconnected_girder] = ...
  set_member_girder_through_block(dbc, com);
[isthrough_kbrace, idconnected_kbrace] = ...
  set_member_girder_through_kbrace_block(com);
isthrough_girder = isthrough_girder | isthrough_kbrace;
mask = (idconnected_kbrace~=0);
idconnected_girder(mask) = idconnected_kbrace(mask);
member_girder.isthrough = isthrough_girder;
member_girder.idconnected_girder = idconnected_girder;
member.girder = member_girder;
com.member = member;

%% 通し柱
[isthrough_column, idconnected_column] = ...
  set_member_column_through_block(dbc, com);
member_column.isthrough = isthrough_column;
member_column.idconnected = idconnected_column;
member.column = member_column;
com.member = member;

%% 柱脚断面
[section_column_base, idme2seccb] = set_section_column_base_block( ...
  dbc, com);
member_property.idseccb = idme2seccb;
member.property = member_property;
com.member = member;
section.column_base = section_column_base;
com.section = section;
com.nseccb = size(section_column_base,1);

%% 梁の横補剛
girder_stiffening = set_member_girder_stiffening_block(dbc, com);
% member_girder.stiffening_Lb = member_girder_stiffening.Lb;
% member.girder = member_girder;
% com.member = member;
com.girder_stiffening = girder_stiffening;

%% 柱の座屈長さ係数（直接入力）
com.column_buckling_K = set_member_column_buckling_length_block(dbc, com);

%% 節点自由度の数え上げ
[idnode2df, idnode2ind, idstory2noderep, xr, yr, ndf, idf2node, ...
  story_isrigid] = countup_node2df(com);
node.dof = idnode2df;
node.ind = idnode2ind;
node.xr = xr;
node.yr = yr;
story.idnoderep = idstory2noderep;
story.isrigid = story_isrigid;
com.node = node;
com.story = story;
com.ndf = ndf;
com.idf2node = idf2node;

%% スラブ協力幅
com.member.girder = set_member_girder_slab_block(dbc, com);

%% 柱の剛度増減率
column_phiI = set_member_column_phi_block(dbc, com);
com.member.column.phiI = column_phiI;

%% 梁の剛度増減率
[girder_phiI, girder_phiAs] = set_girder_phi_block(dbc, com);
com.member.girder.phiI = girder_phiI;
com.member.girder.phiAs = girder_phiAs;

%% 捩り剛性増減率（梁・柱、com.member.property.factor_J に上書き）
factor_J = com.member.property.factor_J;
factor_J = set_factor_J_girder_block(dbc, com, factor_J);
factor_J = set_factor_J_column_block(dbc, com, factor_J);
com.member.property.factor_J = factor_J;

%% 断面算定の省略（梁符号毎）
istarget = set_exclusion_girder_stress_block(dbc, com);
com.exclusion.is_section_girder_allowable_stress = istarget;

%% 断面算定の省略（柱符号毎）
istarget = set_exclusion_column_stress_block(dbc, com);
com.exclusion.is_section_column_allowable_stress = istarget;

%% 梁せい分布除外
idexclusion = set_exclusion_girder_smooth_block(dbc, com);
com.exclusion.girder_smooth.idme = idexclusion;

%% 柱外径差制限の除外
idexclusion = set_exclusion_column_diameter_gap_block(dbc, com);
com.exclusion.column_diameter_gap.idme = idexclusion;

%% 名目梁（set_girder_force_blockで使用）
[nominal_girder, idnominal_girder] = countup_nominal_girder(com);
com.nominal.girder = nominal_girder;
com.member.girder.idnominal = idnominal_girder;

%% 荷重ケース
loadcase = set_loadcase_block(dbc);
com.loadcase = loadcase;
com.nlc = size(loadcase,1);

%% 節点荷重
fnode = set_nodal_force_block(dbc, com);
fnode = add_earthquake_force_position_mz(dbc, com, fnode);

%% 追加節点荷重
[faddnode, faddnode_report_excl] = set_additive_nodal_force_block(...
  dbc, com);

%% 要素荷重
[ar, M0] = set_girder_force_block(dbc, com);

%% 荷重ベクトルの保存
com.fnode = fnode;
com.faddnode = faddnode;
com.faddnode_report_excl = faddnode_report_excl;
com.ar = ar;
com.M0 = M0;

return
end

%--------------------------------------------------------------------------
function options = set_basic_options_block(dbc, options)
data = dbc.get_data_block('基本事項');
options = options.setFromDataBlock(data);
return
end

%--------------------------------------------------------------------------
function options = set_analysis_options_block(dbc, options)
data = dbc.get_data_block('構造計算条件');
options = options.setFromDataBlock(data);
return
end

%--------------------------------------------------------------------------
function options = set_optimization_options_block(dbc, options)
data = dbc.get_data_block('最適化条件');
options = options.setFromDataBlock(data);
return
end

%--------------------------------------------------------------------------
function coptions = set_constraints_block(dbc, coptions)
data = dbc.get_data_block('制約条件');
coptions = coptions.setFromDataBlock(data);
return
end

%--------------------------------------------------------------------------
function options = set_output_options_block(dbc, options)
data = dbc.get_data_block('出力制御');

label = 0;
for i=1:size(data,1)
  % if ismissing(data{i,1})
  %   continue
  % end

  % --- 出力制御用の対象 ---
  val = tochar(data{i,1});
  if ismissing(val)
    val = '';
  end
  switch val
    case '梁断面リスト'
      label = PRM.GIRDER;
    case '柱断面リスト'
      label = PRM.COLUMN;
  end

  % --- 出力制御用のオプション値読み込み ---
  ncol = size(data,2)-1;
  for j=2:size(data,2)
    if ismissing(data{i,j})
      ncol = j-1;
      break
    end
    if isempty(data{i,j})
      ncol = j-1;
      break
    end
  end

  % --- 出力制御用のオプション値セット ---
  switch label
    case PRM.GIRDER
      if isempty(options.output_girder_list_label)
        options.output_girder_list_label = data(i,2:ncol);
      else
        options.output_girder_list_label = ...
          [options.output_girder_list_label data(i,2:ncol)];
      end
    case PRM.COLUMN
      if isempty(options.output_column_list_label)
        options.output_column_list_label = data(i,2:ncol);
      else
        options.output_column_list_label = ...
          [options.output_column_list_label data(i,2:ncol)];
      end
  end
end

% options = options.setFromDataBlock(data);
return
end

%--------------------------------------------------------------------------
function  variable = set_variable_block(dbc)
data = dbc.get_data_block('設計変数');
n = size(data,1);
nmax = max(PRM.MAX_NVAR, n);
name = cell(nmax,1);
isvar = nan(nmax,1);
value = zeros(nmax,1);
idvar = zeros(nmax,1);
id = 0;
for i=1:nmax
  name{i} = '';
end
for i=1:n
  name{i} = tochar(data{i,1});

  % 変数／固定
  isvar_ = data{i,2};
  if ismissing(isvar_)
    isvar_ = 'T';
  end
  if isvar_ == 'F'
    isvar(i) = false;
  else
    isvar(i) = true;
  end

  % 変数番号
  % if isvar(i)
  id = id+1;
  idvar(i) = id;
  % end

  value_ = data{i,3};
  if ~ismissing(value_)
    value(i) = value_;
  end
end

% 結果の保存
variable = table(name, isvar, value, idvar);
return
end

%--------------------------------------------------------------------------
function material = set_material_block(dbc)
data = dbc.get_data_block('材料');
n = size(data,1);
id = zeros(n,1);
name = cell(n,1);
E = zeros(n,1);
pr = zeros(n,1);
G = zeros(n,1);
F = zeros(n,1);
isSN = false(n,1);
steel_grade = zeros(n,1);
for i = 1:n
  id(i) = i;
  name{i} = tochar(data{i,1});
  E(i) = data{i,2};
  pr(i) = data{i,3};
  F(i) = data{i,4};
  G(i) = calc_shear_modulus(E(i), pr(i));
  if length(name{i})>=2
    prefix = name{i}(1:2);
    switch prefix
      case "SS"
        steel_grade(i) = PRM.GRADE_SS;
      case "SN"
        steel_grade(i) = PRM.GRADE_SN;
        isSN(i) = true;
      case "SM"
        steel_grade(i) = PRM.GRADE_SM;
    end
  end
end

% 結果の保存
material = table(id, name, E, pr, G, F, isSN, steel_grade);
return
end

%--------------------------------------------------------------------------
function G = calc_shear_modulus(E, pr)
%calc_shear_modulus - せん断弾性係数を算出する
%   pr=0.3 のとき SS7 規定値 G=79400 N/mm2 を返す。
%   それ以外は G = E/(2(1+pr)) で算出する。
if pr == 0.3
  G = 79400;
else
  G = E/(2*(1+pr));
end
return
end

%--------------------------------------------------------------------------
function section_list = set_section_list_block(dbc, input, com)
data = dbc.get_data_block('断面リスト');
n = size(data,1);

% 符号・材料・リストファイル名
section_list_name_ = cell(n,1);
section_type_name_ = cell(n,1);
material_name_ = cell(n,1);
file_name_ = cell(n,1);
cost_factor_ = zeros(n,1);
cost_constant_ = zeros(n,1);
design_stress_factor_ = ones(n,1);
idphase_ = ones(n,1);
type_name_ = cell(n,1);
isSN_ = false(n,1);
for i=1:n
  section_list_name_{i} = tochar(data{i,1});
  section_type_name_{i} = tochar(data{i,2});
  material_name_{i} = tochar(data{i,3});
  file_name_{i}  = tochar(data{i,4});
  val = data{i,5};
  if ismissing(val)
    cost_factor_(i) = 1;
  else
    cost_factor_(i) = val;
  end
  % design_stress_factor_(i) = 1;
  % val = data{i,6};
  % if ismissing(val) || val==0
  %   design_stress_factor_(i) = 1;
  % else
  %   design_stress_factor_(i) = val;
  % end
  val = data{i,6};
  if ~ismissing(val)
    cost_constant_(i) = val;
  end
  val = data{i,7};
  if ismissing(val)
    idphase_(i) = 1;
  else
    idphase_(i) = val;
  end
  nphase_required = idphase_(i) + 1;
  if nphase_required > PRM.MAX_NUM_PHASE
    dbc.throw_dat_err('断面リスト', i, 'Input', 'ExceedMaxPhase', ...
      nphase_required, PRM.MAX_NUM_PHASE);
  end
  val = data{i,8};
  if ismissing(val)
    type_name_{i} = [];
  else
    type_name_{i} = val;
  end
end

% 断面タイプ
section_type_ = PRM.get_id_section_type(section_type_name_);

% 材料
idmaterial_ = zeros(n,1); iddd = 1:com.nma;
for i=1:n
  material_name__ = material_name_{i};
  if ~ismissing(material_name__)
    if ~strcmp(material_name__, '-')
      idmaterial_(i) = iddd(matches(com.material.name, material_name_{i}));
      isSN_(i) = com.material.isSN(idmaterial_(i));
    end
  end
end

% リストファイル
listdir = fileparts(input);
section_list = SectionListHandler(listdir);

% リストの合成
[section_list_name, iu1, iu2] = unique(section_list_name_, 'stable');
nulist = length(section_list_name);
nlist = zeros(nulist,1);

% 鉄骨形状のチェック：同一リストでは同一の鉄骨形状のみ指定可
for i=1:nulist
  target = (iu2==i);
  nlist(i) = sum(target);
  st_ = unique(section_type_(target));
  if length(st_)~=1
    ME = MException('YLAB:InvalidSectionList', ...
      '同一断面リストに対する鉄骨形状は同一としてください');
    throw(ME);
  end
end
section_type_name = section_type_name_(iu1);
section_type = section_type_(iu1);

% その他
material_name = cell(nulist,PRM.MAX_SECTION_LIST);
file_name = cell(nulist,PRM.MAX_SECTION_LIST);
idmaterial = zeros(nulist,PRM.MAX_SECTION_LIST);
cost_factor = zeros(nulist,PRM.MAX_SECTION_LIST);
cost_constant = zeros(nulist,PRM.MAX_SECTION_LIST);
design_stress_factor = zeros(nulist,PRM.MAX_SECTION_LIST);
isSN = false(nulist,PRM.MAX_SECTION_LIST);
idphase = zeros(nulist,PRM.MAX_SECTION_LIST);
type_name = cell(nulist,PRM.MAX_SECTION_LIST);
iddd = 1:n;
for i=1:nulist
  target = iddd(iu2==i);
  for j=1:length(target)
    material_name(i,j) = material_name_(target(j));
    file_name(i,j) = file_name_(target(j));
    idmaterial(i,j) = idmaterial_(target(j));
    cost_factor(i,j) = cost_factor_(target(j));
    cost_constant(i,j) = cost_constant_(target(j));
    design_stress_factor(i,j) = design_stress_factor_(target(j));
    isSN(i,j) = isSN_(target(j));
    idphase(i,j) = idphase_(target(j));
    type_name(i,j) = type_name_(target(j));
  end
end

% 結果の保存
section_list = section_list.registerList(section_type, ...
  section_type_name, nlist, section_list_name, material_name, ...
  file_name, idmaterial, cost_factor, cost_constant, ...
  design_stress_factor, isSN, idphase, type_name);
return
end

%--------------------------------------------------------------------------
function column_base_list = set_column_base_list_block(dbc, input, ~)
data = dbc.get_data_block('柱脚リスト');
n = size(data,1);

% 符号・材料・リストファイル名
column_base_list(1:n) = struct('D', [], 'kbs', [], 'Df', [], ...
  'type', [], 'name', [], 'list_name', [], 'list_dir', [], ...
  'file_name', []);

% list_name = cell(n,1);
% file_name = cell(n,1);
% body = cell(n,1);
list_dir = fileparts(input);
for i=1:n
  % ファイル読み込み
  list_name = tochar(data{i,1});
  file_name  = tochar(data{i,2});
  full_file_name = fullfile(list_dir, file_name);
  tmp = readcell(full_file_name, CommentStyle='%', Range=2);

  % 属性値のセット
  if isempty(tmp)
    break
  end
  type = tmp(:,1);
  name = tmp(:,2);
  tmp = readmatrix(full_file_name, CommentStyle='%', Range=2);
  D = tmp(:,3);
  kbs = tmp(:,4);
  Df = tmp(:,5);

  % 結果の保存
  column_base_list(i).D = D;
  column_base_list(i).kbs = kbs;
  column_base_list(i).Df = Df;
  column_base_list(i).type = type;
  column_base_list(i).name = name;
  column_base_list(i).list_name = list_name;
  column_base_list(i).list_dir = list_dir;
  column_base_list(i).file_name = file_name;
end

return
end

%--------------------------------------------------------------------------
function node = set_node_identification_block(dbc, com)
% 計算の準備
baseline = com.baseline;
node = com.node;
data = dbc.get_data_block('節点の同一化');
n = size(data,1);

% 層名・通り名
story_name1 = cell(n,1);
coord_name1 = cell(n,2);
story_name2 = cell(n,1);
coord_name2 = cell(n,2);
for i=1:n
  story_name1{i} = tochar(data{i,1});
  coord_name1(i,:) = tochar(data(i,2:3));
  story_name2{i} = tochar(data{i,4});
  coord_name2(i,:) = tochar(data(i,5:6));
end

% 節点番号検索
[idx1, idy1, idz1] = find_idxyz_node(story_name1, coord_name1, baseline);
idnode1 = find_idnode_from_idxyz(idx1, idy1, idz1, node);
[idx2, idy2, idz2] = find_idxyz_node(story_name2, coord_name2, baseline);
idnode2 = find_idnode_from_idxyz(idx2, idy2, idz2, node);

% 存在しない節点はスキップ
isdummy = idnode1==0 | idnode2==0;
idnode1 = idnode1(~isdummy);
idnode2 = idnode2(~isdummy);
n = length(idnode1);

% 節点1->節点2
for i=1:n
  node.x(idnode1(i)) = node.x(idnode2(i));
  node.y(idnode1(i)) = node.y(idnode2(i));
  node.z(idnode1(i)) = node.z(idnode2(i));
end

% 代表節点
nnode = size(node,1);
idrep = zeros(nnode,1);
for i=1:n
  idrep(idnode1(i)) = idnode2(i);
end

node.idrep = idrep;

% 吸収節点の無効化（fail-fast）
% 同一化元節点は以降の剛床・DOF処理から除外するため type を
% NODE_ABSORBED に変更し、idstory を 0 にする。idx/idy/idz は
% find_idnode_from_idxyz による位置検索 → idrep 経由代表置換を
% 成立させるため保持する。以降のメンバー登録処理では吸収節点の
% 位置を指定しても自動的に代表節点番号が返される。
for i=1:n
  in = idnode1(i);
  node.type(in) = PRM.NODE_ABSORBED;
  node.idstory(in) = 0;
end
end

%--------------------------------------------------------------------------
function support = set_support_condition(dbc, com)
data = dbc.get_data_block('支点');
n = size(data,1);

% 通り・層名
xname = cell(n,1);
yname = cell(n,1);
% zname = cell(n,1);
story_name = cell(n,1);
isfixed = false(n,6);

for i=1:n
  xname{i} = tochar(data{i,2});
  yname{i} = tochar(data{i,3});
  story_name{i} = tochar(data{i,1});
  isfixed(i,:) = matches(data(i,4:9),'T');
end

% θx,θyの入れ替え
isfixed(:,[4 5]) = isfixed(:,[5 4]);

% 通り・層番号
idx = zeros(n,1); iddx = 1:com.nblx;
idy = zeros(n,1); iddy = 1:com.nbly;
idstory = zeros(n,1); iddz = 1:com.nblz;
for i=1:n
  idx(i) = iddx(matches(com.baseline.x.name, xname{i}));
  idy(i) = iddy(matches(com.baseline.y.name, yname{i}));
  idstory(i) = iddz(matches(com.story.name, story_name{i}));
end

% 節点番号
idnode = zeros(n,1);
iddn = 1:com.nnode;
for i=1:n
  idnode(i) = iddn(com.node.idx==idx(i) ...
    & com.node.idy==idy(i) & com.node.idstory==idstory(i));
end

% 結果の保存
support = table(xname, yname, story_name, isfixed, idx, idy, ...
  idstory, idnode);
return
end

%--------------------------------------------------------------------------
function flex_diaphragm = set_flexible_diaphragm(dbc, com)
data = dbc.get_data_block('剛床仮定の解除');
n = size(data,1);

% 通り・層名
story_name = cell(n,1);
xname = cell(n,1);
yname = cell(n,1);
isflex = true(n,1);

for i=1:n
  story_name{i} = tochar(data{i,1});
  xname{i} = tochar(data{i,2});
  yname{i} = tochar(data{i,3});
  isflex(i) = matches(data(i,5),'T');
end

% 通り・層番号
idx = zeros(n,1); iddx = 1:com.nblx;
idy = zeros(n,1); iddy = 1:com.nbly;
idstory = zeros(n,1); iddz = 1:com.nblz;
for i=1:n
  idx(i) = iddx(matches(com.baseline.x.name, xname{i}));
  idy(i) = iddy(matches(com.baseline.y.name, yname{i}));
  idstory(i) = iddz(matches(com.story.name, story_name{i}));
end

% 節点番号
idnode = zeros(n,1);
iddn = 1:com.nnode;
for i=1:n
  idn_ = iddn(com.node.idx==idx(i) ...
    & com.node.idy==idy(i) & com.node.idstory==idstory(i));
  if ~isempty(idn_)
    idnode(i) = idn_;
  end
end

% 結果の保存
idvalid = idnode>0;
xname = xname(idvalid);
yname = yname(idvalid);
story_name = story_name(idvalid);
isflex = isflex(idvalid);
idx = idx(idvalid);
idy = idy(idvalid);
idstory = idstory(idvalid);
idnode = idnode (idvalid);
flex_diaphragm = table(xname, yname, story_name, isflex, ...
  idx, idy, idstory, idnode);
return
end

%--------------------------------------------------------------------------
function [column_base, idme2seccb] = set_section_column_base_block( ...
  dbc, com)
data = dbc.get_data_block('メーカー製柱脚断面');
n = size(data,1);

% 共通配列
section_column = com.section.column;
% node = com.node;
% x = node.x;
% y = node.y;
% z = node.z;

% 階名
floor_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
end

% % 通り名
% coord_name = cell(n,2);
% for i=1:n
%   coord_name(i,:) = tochar(data(i,2:3));
% end

% 断面符号
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,2});
end

% 柱脚属性
type = zeros(n,1);
property = zeros(n,1);
idlist = zeros(n,1); iddl = 1:com.ncblist;
for i=1:n
  name = tochar(data{i,3});
  switch name
    case "剛性指定"
      type(i) = PRM.CB_DIRECT;
      property(i) = data{i,4};
    otherwise
      type(i) = PRM.CB_LIST;
      if ~isempty(com.column_base_list.list_name)
        idlist(i) = iddl(matches(com.column_base_list.list_name, name));
      end
  end
end

% 番号
idstory = zeros(n,1); idds = 1:com.nstory;
for i=1:n
  idstory(i) = idds(matches(com.story.floor_name, floor_name{i}));
end

% 断面番号
idsecc = zeros(n,1); iddl = 1:com.nsecc;
for i=1:n
  id = iddl(matches(section_column.name, section_name{i}) ...
    & section_column.idstory==idstory(i));
  if isempty(id)
    id = iddl(matches(section_column.full_name, section_name{i}));
  end
  idsecc(i) = id;
end

% ID逆引き
idme2seccb = zeros(com.nme,1);
idm2sc = com.member.property.idsecc;
idmc2story = com.member.column.idstory;
idm2story = zeros(com.nme,1);
idm2story(com.member.column.idme) = idmc2story;
% idmc2z = com.member.column.idz(:,1);
% idm2z = zeros(com.nme,1);
% idm2z(com.member.column.idme) = idmc2z;
idmc2ctype = com.member.column.type;
idm2ctype = zeros(com.nme,1);
idm2ctype(com.member.column.idme) = idmc2ctype;

% 柱脚との関係付け
for i=1:n
  idsc = idsecc(i);
  idme2seccb(idm2sc==idsc&idm2story==2&idm2ctype==PRM.COLUMN_STANDARD) = i;
  idme2seccb(idm2sc==idsc & idm2story==2 ...
    & idm2ctype==PRM.COLUMN_FOR_BRACE_BODY) = i;
  % idme2seccb(idm2sc==idsc & idm2story==2 ...
  %   & idm2ctype==PRM.COLUMN_FOR_BRACE) = i;
  % idme2seccb(idm2sc==idsc&idm2z==1) = i;
end

% 結果の保存
% column_base = table(floor_name, coord_name, section_name, ...
%   type, property, idlist, idstory, idx, idy, idz, idsecc, idmec, idme);
column_base = table(floor_name, section_name, type, ...
  property, idlist, idstory, idsecc);
return
end

%--------------------------------------------------------------------------
function section_brace = set_section_horizontal_brace_block(dbc, ~)

% 計算の準備
data = dbc.get_data_block('水平ブレース断面');
n = size(data,1);

% 断面符号
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,1});
end

% 断面リスト
type = zeros(n,1);
type_name = cell(n,1);
% tctype = zeros(n,1);
A = zeros(n,1);
E = zeros(n,1);
unit_weight = zeros(n,1);
for i=1:n
  % 種別
  type(i) = PRM.HBR;
  type_name{i} = '水平ブレース';

  % 断面積
  value_ = data{i,2};
  if ~ismissing(value_)
    A(i)= value_;
  end

  % ヤング係数
  value_ = data{i,3};
  if ~ismissing(value_)
    E(i)= value_;
  end

  % 単位容積重量
  value_ = data{i,4};
  if ~ismissing(value_)
    unit_weight(i)= value_;
  end
end

% 寸法指定
mvar = PRM.MAX_NSVAR;
dimension = zeros(n,mvar);
dimension(:,1:3) = [A E unit_weight];

% 結果の保存
name = section_name;
% id_section_list = zeros(n,1);
% mvar = PRM.MAX_NSVAR;
% idvar = zeros(n,mvar);
section_brace = table(name, type_name, type, A, E, unit_weight, dimension);
return
end
%--------------------------------------------------------------------------
function [member_property, idmec2mem, idmeg2mem, idmeb2mem, ...
  idmehb2mem] = set_member_property(com)
% 共通定数
nme = com.nme;
nmec = com.nmec;
nmeg = com.nmeg;
nmeb = com.nmeb;
nmehb = com.nmehb;

% 共通配列
member_column = com.member.column;
member_girder = com.member.girder;
member_brace = com.member.brace;
member_horizontal_brace = com.member.horizontal_brace;
section_column = com.section.column;
section_girder = com.section.girder;
section_brace = com.section.brace;
section_horizontal_brace = com.section.horizontal_brace;
% 部材種別
type = [repmat(PRM.GIRDER,nmeg,1); repmat(PRM.COLUMN,nmec,1); ...
  repmat(PRM.BRACE,nmeb,1); repmat(PRM.HORIZONTAL_BRACE,nmehb,1)];

% 部材番号
idmeg = zeros(nme,1);
idmeg(type==PRM.GIRDER) = 1:nmeg;
idmec = zeros(nme,1);
idmec(type==PRM.COLUMN) = 1:nmec;
idmeb = zeros(nme,1);
idmeb(type==PRM.BRACE) = 1:nmeb;
idmehb = zeros(nme,1);
idmehb(type==PRM.HORIZONTAL_BRACE) = 1:nmehb;

% 部材番号の逆引き（柱）
iccc = 1:nme; iccc = iccc(idmec>0);
idmec2mem = zeros(nmec,1);
idmec2mem(idmec(idmec>0)) = iccc;

% 部材番号の逆引き（梁）
iggg = 1:nme; iggg = iggg(idmeg>0);
idmeg2mem = zeros(nmeg,1);
idmeg2mem(idmeg(idmeg>0)) = iggg;

% 部材番号の逆引き（ブレース）
ibbb = 1:nme; ibbb = ibbb(idmeb>0);
idmeb2mem = zeros(nmeb,1);
idmeb2mem(idmeb(idmeb>0)) = ibbb;

% 部材番号の逆引き（水平ブレース）
ihbbb = 1:nme; ihbbb = ihbbb(idmehb>0);
idmehb2mem = zeros(nmehb,1);
idmehb2mem(idmehb(idmehb>0)) = ihbbb;

% 断面番号
idsecc = zeros(nme,1); idsecc(type==PRM.COLUMN) = member_column.idsecc;
idsecg = zeros(nme,1); idsecg(type==PRM.GIRDER) = member_girder.idsecg;
idsecb = zeros(nme,1); idsecb(type==PRM.BRACE) = member_brace.idsecb;
idsechb = zeros(nme,1);
idsechb(type==PRM.HORIZONTAL_BRACE) = member_horizontal_brace.idsechb;
idsec = zeros(nme,1);
idsec(type==PRM.COLUMN) = section_column.idsec(idsecc(type==PRM.COLUMN));
idsec(type==PRM.GIRDER) = section_girder.idsec(idsecg(type==PRM.GIRDER));
idsec(type==PRM.BRACE) = section_brace.idsec(idsecb(type==PRM.BRACE));
idsec(type==PRM.HORIZONTAL_BRACE) = ...
  section_horizontal_brace.idsec(idsechb(type==PRM.HORIZONTAL_BRACE));

% 層番号
idstory = zeros(nme,1);
idstory(type==PRM.COLUMN) = member_column.idstory;
idstory(type==PRM.GIRDER) = member_girder.idstory;
idstory(type==PRM.BRACE) = member_brace.idstory;

% 断面種別
section_type = zeros(nme,1);
section_type(type==PRM.COLUMN) = section_column.type(member_column.idsecc);
section_type(type==PRM.GIRDER) = section_girder.type(member_girder.idsecg);
section_type(type==PRM.BRACE) = section_brace.type(member_brace.idsecb);
section_type(type==PRM.HORIZONTAL_BRACE) = ...
  section_horizontal_brace.type(member_horizontal_brace.idsechb);

% 節点番号
idnode1 = zeros(nme,1);
idnode2 = zeros(nme,1);
idnode1(type==PRM.GIRDER) = com.member.girder.idnode1;
idnode2(type==PRM.GIRDER) = com.member.girder.idnode2;
idnode1(type==PRM.COLUMN) = com.member.column.idnode1;
idnode2(type==PRM.COLUMN) = com.member.column.idnode2;
idnode1(type==PRM.BRACE) = com.member.brace.idnode1;
idnode2(type==PRM.BRACE) = com.member.brace.idnode2;
idnode1(type==PRM.HORIZONTAL_BRACE) = com.member.horizontal_brace.idnode1;
idnode2(type==PRM.HORIZONTAL_BRACE) = com.member.horizontal_brace.idnode2;

% 変数番号
mvar = PRM.MAX_NSVAR;
idvar = zeros(nme,mvar);
idvar(type==PRM.COLUMN,:) = section_column.idvar(member_column.idsecc,:);
idvar(type==PRM.GIRDER,:) = section_girder.idvar(member_girder.idsecg,:);
idvar(type==PRM.BRACE,:) = section_brace.idvar(member_brace.idsecb,:);

% 向き
idir = zeros(nme,1);
idir(type==PRM.GIRDER) = member_girder.idir;
idir(type==PRM.BRACE) = member_brace.idir;

% 引張のみ判定（水平ブレース・部材レベル）
is_tension_only_hb = false(nme, 1);
if nmehb > 0
  is_tension_only_hb(type == PRM.HORIZONTAL_BRACE) = ...
    member_horizontal_brace.tctype == PRM.BRACE_TENSION;
end

% 捩り剛性増減率の初期値（SS7 §5.2 準拠で全部材 0=微小化）
% 入力セクション「梁/柱の捩り剛性増減率」で該当部材が上書きされる
% 0 のまま残った部材は stif_sys_matrix で STIFF_IGNORE_FACTOR 倍される
factor_J = zeros(nme, 1);

% 結果の保存
member_property = table(type, idir, idmeg, idmec, idmeb, ...
  idmehb, section_type, idsec, idsecc, idsecg, idsecb, ...
  idsechb, idnode1, idnode2, idstory, idvar, is_tension_only_hb, ...
  factor_J);
return
end

%--------------------------------------------------------------------------
function [section_property, idsecc2sec, idsecg2sec, idsecb2sec, ...
  idsechb2sec] = set_section_property(com)
% 共通定数
nsec = com.nsec;
nsecc = com.nsecc;
nsecg = com.nsecg;
nsecb = com.nsecb;
nsechb = com.nsechb;

% 共通配列
section_column = com.section.column;
section_girder = com.section.girder;
section_brace = com.section.brace;
section_horizontal_brace = com.section.horizontal_brace;

% 断面種別
mtype = [repmat(PRM.GIRDER,nsecg,1); repmat(PRM.COLUMN,nsecc,1); ...
  repmat(PRM.BRACE,nsecb,1); repmat(PRM.HORIZONTAL_BRACE,nsechb,1)];
type = nan(nsec,1);
type(mtype==PRM.COLUMN) = section_column.type;
type(mtype==PRM.GIRDER) = section_girder.type;
type(mtype==PRM.BRACE) = section_brace.type;
type(mtype==PRM.HORIZONTAL_BRACE) = section_horizontal_brace.type;

% 断面番号
idsecg = zeros(nsec,1);
idsecg(mtype==PRM.GIRDER) = 1:nsecg;
idsecc = zeros(nsec,1);
idsecc(mtype==PRM.COLUMN) = 1:nsecc;
idsecb = zeros(nsec,1);
idsecb(mtype==PRM.BRACE) = 1:nsecb;
idsechb = zeros(nsec,1);
idsechb(mtype==PRM.HORIZONTAL_BRACE) = 1:nsechb;

% 層番号
idstory = zeros(nsec,1);
idstory(mtype==PRM.GIRDER) = section_girder.idstory;
idstory(mtype==PRM.COLUMN) = section_column.idstory;

% 断面リスト番号
% id_section_list = zeros(nsec,PRM.MAX_SECTION_LIST);
id_section_list = zeros(nsec,1);
id_section_list(mtype==PRM.GIRDER) = section_girder.id_section_list;
id_section_list(mtype==PRM.COLUMN) = section_column.id_section_list;
id_section_list(mtype==PRM.BRACE) = section_brace.id_section_list;

% 材料番号
idmaterial = zeros(nsec,1);
idmaterial(mtype==PRM.GIRDER) = section_girder.idmaterial;
idmaterial(mtype==PRM.COLUMN) = section_column.idmaterial;

% 断面番号の逆引き（柱）
iccc = 1:nsec; iccc = iccc(idsecc>0);
idsecc2sec = zeros(nsecc,1);
idsecc2sec(idsecc(idsecc>0)) = iccc;

% 断面番号の逆引き（梁）
iggg = 1:nsec; iggg = iggg(idsecg>0);
idsecg2sec = zeros(nsecg,1);
idsecg2sec(idsecg(idsecg>0)) = iggg;

% 断面番号の逆引き（ブレース）
ibbb = 1:nsec; ibbb = ibbb(idsecb>0);
idsecb2sec = zeros(nsecb,1);
idsecb2sec(idsecb(idsecb>0)) = ibbb;

% 断面番号の逆引き（水平ブレース）
ihbbb = 1:nsec; ihbbb = ihbbb(idsechb>0);
idsechb2sec = zeros(nsechb,1);
idsechb2sec(idsechb(idsechb>0)) = ihbbb;

% 設計変数番号
mvar = PRM.MAX_NSVAR;
idvar = zeros(nsec,mvar);
idvar(mtype==PRM.GIRDER,:) = section_girder.idvar;
idvar(mtype==PRM.COLUMN,:) = section_column.idvar;
idvar(mtype==PRM.BRACE,:) = section_brace.idvar;

% 寸法
mvar = PRM.MAX_NSVAR;
dimension = zeros(nsec,mvar);
dimension(mtype==PRM.GIRDER,:) = section_girder.dimension;
dimension(mtype==PRM.COLUMN,:) = section_column.dimension;
dimension(mtype==PRM.BRACE,:) = section_brace.dimension;
dimension(mtype==PRM.HORIZONTAL_BRACE,:) = ...
  section_horizontal_brace.dimension;

% 結果の保存
section_property = table(idsecg, idsecc, idsecb, idsechb, ...
  idstory, type, mtype, id_section_list, idmaterial, idvar, dimension);
return
end

%--------------------------------------------------------------------------
function initial_section_girder = ...
  set_initial_section_steel_girder_block(dbc, com)

data = dbc.get_data_block('S梁断面(仮定)');
n = size(data,1);

% 層名
story_name = cell(n,1);
for i=1:n
  story_name{i} = tochar(data{i,1});
end

% 層・Z通り番号
idstory = zeros(n,1); idds = 1:com.nstory;
idz = zeros(n,1); iddz = com.story.idz;
for i=1:n
  idstory(i) = idds(matches(com.story.name, story_name{i}));
  idz(i) = iddz(matches(com.story.name, story_name{i}));
end

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字と断面符号
subindex = cell(n,1);
full_name = cell(n,1);
for i=1:n
  subindex{i} = data{i,3};
  if subindex{i}=='-'
    subindex{i} = num2str(idstory(i));
  end
  if isnumeric(subindex{i})
    subindex{i} = num2str(subindex{i});
  end
  full_name{i} = [subindex{i} name{i}];
end

% 鉄骨登録形状
dimension = cell(n,1);
for i=1:n
  dimension{i} = data{i,4};
end

% 結果の保存
initial_section_girder = table(name, subindex , story_name, full_name, ...
  dimension);
return
end

%--------------------------------------------------------------------------
function [section_brace, initial_section_brace] = ...
  set_initial_section_brace_steel_block(dbc, com)
data = dbc.get_data_block('鉛直ブレース断面（鋼材）(仮定)');
n = size(data,1);

% 既存のsection.braceを取得
section_brace = com.section.brace;

if n == 0
  initial_section_brace = table();
  return
end

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

% 登録形状
dimension = cell(n,1);
for i=1:n
  dimension{i} = data{i,2};
end

% 初期値テーブルの作成（HSR断面用）
initial_section_brace = table(name, dimension);

% section.braceへの初期値データの読み込み
for i=1:n
  % 対応する断面を検索
  idx = strcmp(section_brace.name, name{i});
  if any(idx)
    j = find(idx, 1);

    % A (断面積)
    value_ = data{i,3};
    if ~ismissing(value_)
      section_brace.A(j) = value_;
    end

    % ir (回転半径)
    value_ = data{i,4};
    if ~ismissing(value_)
      section_brace.ir(j) = value_;
    end

    % lmbe (有効細長比)
    value_ = data{i,5};
    if ~ismissing(value_)
      section_brace.lmbe(j) = value_;
    end
  end
end

return
end

%--------------------------------------------------------------------------
function initial_section_brace = ...
  set_initial_section_brace_manufacturer_block(dbc, ~)
data = dbc.get_data_block('鉛直ブレース断面（メーカー製品）(仮定)');
n = size(data,1);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

% 登録形状
dimension = cell(n,1);
for i=1:n
  dimension{i} = data{i,2};
end

% 結果の保存
initial_section_brace = table(name, dimension);
return
end

%--------------------------------------------------------------------------
function member_horizontal_brace = ...
  set_member_horizontal_brace_block(dbc, com, ~)
data = dbc.get_data_block('水平ブレース配置');
n = size(data,1);

% 共通配列
node = com.node;
x = node.x;
y = node.y;
z = node.z;
section_horizontal_brace = com.section.horizontal_brace;

% 階名・通り名
id = zeros(n,1);
story_name = cell(n,1);
xcoord_name = cell(n,2);
ycoord_name = cell(n,2);
for i=1:n
  val = data{i,1};
  if ~ismissing(val)
    id(i) = val;
  end
  story_name{i} = tochar(data{i,2});
  xcoord_name(i,:) = tochar(data(i,[3 5]));
  ycoord_name(i,:) = tochar(data(i,[4 6]));
end

% 断面符号
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,7});
end

% ペア
idpair = zeros(n,1);
type = zeros(n,1);
for i=1:n
  val = data{i,8};
  if ismissing(val)
    continue
  end
  if any(val==id)
    idpair(i) = val;
    type(i) = PRM.BRACE_MEMBER_TYPE_X;
    type(val) = PRM.BRACE_MEMBER_TYPE_X;
  end
end

% 引張／引圧
tctype = repmat(PRM.BRACE_TENSION_COMPRESSION, n, 1);
for i = 1:n
  val = data{i, 9};
  if ~ismissing(val)
    val = tochar(val);
    if contains(val, '引張') && ~contains(val, '引圧')
      tctype(i) = PRM.BRACE_TENSION;
    end
  end
end

% 層番号
idstory = zeros(n,1); idds = 1:com.nstory;
for i=1:n
  idstory(i) = idds(matches(com.story.name, story_name{i}));
end

% 通り番号・方向
[idx, idy, idz] = find_idxy_story_coord(story_name, ...
  xcoord_name, ycoord_name, com.baseline, com.story);

% 断面番号
idsechb = zeros(n,1); iddd = 1:com.nsechb;
for i=1:n
  id = iddd(matches(section_horizontal_brace.name, section_name{i}));
  idsechb(i) = id;
end

% 断面種別
section_type = section_horizontal_brace.type(idsechb);

% 節点番号
idnode1 = zeros(n,1);
idnode2 = zeros(n,1);
for i=1:n
  idnode1(i) = find_idnode_from_idxyz(idx(i,1), idy(i,1), idz(i,1), node);
  idnode2(i) = find_idnode_from_idxyz(idx(i,2), idy(i,2), idz(i,1), node);
end

% 方向余弦の計算
an = zeros(n,1);
[cyl, cxl] = ystar(x(idnode1), y(idnode1), z(idnode1), ...
  x(idnode2), y(idnode2), z(idnode2), an);

% 結果の保存
member_horizontal_brace = table(story_name, xcoord_name, ...
  ycoord_name, section_name, section_type, idpair, tctype, ...
  idstory, idx, idy, idz, idsechb, idnode1, idnode2, cxl, cyl);

return
end

%--------------------------------------------------------------------------
% function alignment = set_member_girder_alignment_block(dbc, com)
% data = dbc.get_data_block('大梁の寄り');
% n = size(data,1);

% % 共通定数
% nblx = com.nblx;
% nbly = com.nbly;

% % データ読み取り
% xy_frame_name = cell(n,1);
% alignment_column = zeros(n,1);
% alignment_girder = zeros(n,1);
% for i=1:n
%   xy_frame_name{i} = tochar(data{i,1});
%   alignment_column(i) = data{i,2};
%   alignment_girder(i) = data{i,3};
% end

% % 通り番号の検索
% idir = zeros(n,1);
% idxy = zeros(n,1); iddd = 1:max([nblx nbly]);
% for i=1:n
%   % X通り
%   idx = matches(com.baseline.x.name, xy_frame_name{i});
%   if any(idx)
%     idir(i) = PRM.X;
%     idxy(i) = iddd(idx);
%     continue
%   end

%   % Y通り
%   idy = matches(com.baseline.y.name, xy_frame_name{i});
%   if any(idy)
%     idir(i) = PRM.Y;
%     idxy(i) = iddd(idy);
%   end
% end

% % X方向
% idx = idxy(idir==PRM.X);
% frame_name = cell(nblx,1);
% column = zeros(nblx,1);
% girder = zeros(nblx,1);
% frame_name(idx) = xy_frame_name(idir==PRM.X);
% column(idx) = alignment_column(idir==PRM.X);
% girder(idx) = alignment_girder(idir==PRM.X);
% x = table(frame_name, column, girder);

% % Y方向
% idy = idxy(idir==PRM.Y);
% frame_name = cell(nbly,1);
% column = zeros(nbly,1);
% girder = zeros(nbly,1);
% frame_name(idy) = xy_frame_name(idir==PRM.Y);
% column(idy) = alignment_column(idir==PRM.Y);
% girder(idy) = alignment_girder(idir==PRM.Y);
% y = table(frame_name, column, girder);

% % 結果の保存
% alignment.x = x;
% alignment.y = y;
% return
% end

%--------------------------------------------------------------------------
function joint = set_member_girder_joint_block(dbc, com)
data = dbc.get_data_block('梁の結合状態');
n = size(data,1);

% 共通配列
baseline = com.baseline;
member_girder = com.member.girder;
nmeg = com.nmeg;

% 層名・通り名
story_name = cell(n,1);
frame_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,1});
  frame_name{i} = tochar(data{i,2});
  coord_name(i,:) = tochar(data(i,3:4));
end

% 梁部材番号
[idx, idy, idz, ~] = find_idxyz_girder(story_name, frame_name, ...
  coord_name, baseline);
idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder, ...
  [], baseline);

% 結合状態
joint = PRM.FIX*ones(nmeg,4);
for i=1:n
  ids = idmeg(i,:);
  ids = ids(ids > 0);
  if isempty(ids); continue; end
  for j=1:4
    val = data{i,j+4};
    if ismissing(val); continue; end
    switch val
      case 0
        joint(ids,j) = PRM.PIN;
      otherwise
        joint(ids,j) = PRM.FIX;
    end
  end
end

return
end

%--------------------------------------------------------------------------
function joint = set_member_column_joint_block(dbc, com)
%set_member_column_joint_block - 柱の結合状態を読み込む
%
%   joint = set_member_column_joint_block(dbc, com) は、
%   CSVデータブロック「柱の結合状態」から柱部材の
%   結合状態（ピン/固定）を読み込み、柱部材配列に
%   対応する結合状態配列を返す。
%
%   入力引数:
%     dbc - データブロッククラスオブジェクト
%     com - 共通データ構造体
%
%   出力引数:
%     joint - 結合状態 [nmec x 4]
%       列順: X柱脚, X柱頭, Y柱脚, Y柱頭
%       値: PRM.FIX(固定) / PRM.PIN(ピン)
%
%   備考:
%     CSVデータ構造:
%     階, X軸, Y軸, 結合状態(X)柱頭, 結合状態(X)柱脚,
%     結合状態(Y)柱頭, 結合状態(Y)柱脚
%     結合状態: 0=ピン, それ以外=固定

data = dbc.get_data_block('柱の結合状態');
n = size(data,1);

% 共通配列
baseline = com.baseline;
story = com.story;
member_column = com.member.column;
nmec = com.nmec;

% 層名・通り名の抽出
floor_name = cell(n,1);
xcoord_name = cell(n,1);
ycoord_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
  xcoord_name{i} = tochar(data{i,2});
  ycoord_name{i} = tochar(data{i,3});
end

% 柱部材番号の特定
[idx_search, idy_search, idz_search] = find_idxyz_column(...
  floor_name, xcoord_name, ycoord_name, baseline, story);

% 結合状態の設定
% joint配列の構成: [X方向柱脚, X方向柱頭, Y方向柱脚, Y方向柱頭]
joint = PRM.FIX*ones(nmec,4);

for i=1:n
  idmec = find_idcolumn_from_idxyz(idx_search(i,:), ...
    idy_search(i,:), idz_search(i,:), member_column);

  if isempty(idmec)
    continue  % 部材が見つからない場合はスキップ
  end
  im = idmec;

  % 結合状態の読み取り (4列目～7列目)
  % 4列目: 結合状態(X)柱頭
  % 5列目: 結合状態(X)柱脚
  % 6列目: 結合状態(Y)柱頭
  % 7列目: 結合状態(Y)柱脚
  for j=1:4
    val = data{i,j+3};
    if ismissing(val)
      continue
    end

    switch val
      case 0
        joint(im,j) = PRM.PIN;
      otherwise
        joint(im,j) = PRM.FIX;
    end
  end
end

% 柱頭・柱脚の位置合わせ
joint = joint(:,[2 1 4 3]);

return
end
%---------------------------------------------------------------------
function girder_stiffening = set_member_girder_stiffening_block(dbc, com)
data = dbc.get_data_block('梁の横補剛');
n = size(data,1);

% 共通配列
baseline = com.baseline;
member_girder = com.member.girder;

% 層名・通り名
story_name = cell(n,1);
frame_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,1});
  frame_name{i} = tochar(data{i,2});
  coord_name(i,:) = tochar(data(i,3:4));
end

% 梁部材番号
[idx, idy, idz, ~] = find_idxyz_girder(story_name, frame_name, ...
  coord_name, baseline);
idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder, ...
  [], baseline);

% % 結合状態
% stiffening.Lb = nan(nmeg,3);
% for i=1:n
%   ig = idmeg(i);
%   stiffening.Lb(ig,1) = data{i,6};
%   stiffening.Lb(ig,2) = data{i,7};
%   stiffening.Lb(ig,3) = data{i,8};
% end

Lb = nan(n,3);
Lb_end = nan(n,4);
xc = nan(n,2);
xc_points = nan(n,3);
for i=1:n
  lb1_l = data{i,6};
  lb2_l = data{i,7};
  lb1_r = data{i,8};
  lb2_r = data{i,9};
  Lbmax = data{i,10};
  x1 = data{i,11};
  x2 = data{i,12};
  x3 = nan;
  if size(data, 2) >= 13 && ~ismissing(data{i,13})
    x3 = data{i,13};
  end

  Lb(i,1) = lb1_l;
  Lb(i,2) = lb1_r;
  Lb(i,3) = Lbmax;
  Lb_end(i,:) = [lb1_l lb2_l lb1_r lb2_r];
  xc(i,1) = x1;
  xc(i,2) = x2;
  if ~ismissing(x3)
    xc_points(i,:) = [x1 x2 x3];
  end
end

% 結果の保存
girder_stiffening = table(idmeg, Lb, Lb_end, xc, xc_points);
return
end

%--------------------------------------------------------------------------
function girder_level = set_member_girder_level_block(dbc, com)
data = dbc.get_data_block('大梁のレベル調整');
n = size(data,1);

% 共通定数
nmg = com.nmeg;

% 共通配列
baseline = com.baseline;
% material = com.material;
member_girder = com.member.girder;

% 層名・通り名
story_name = cell(n,1);
frame_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,1});
  frame_name{i} = tochar(data{i,2});
  coord_name(i,:) = tochar(data(i,3:4));
end

% 通り番号・方向
[idx, idy, idz, ~] = find_idxyz_girder(story_name, frame_name, ...
  coord_name, baseline);

% 梁部材番号
idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder, ...
  [], baseline);

% レベル調整値
girder_level = zeros(nmg,1);
for i=1:n
  ids = idmeg(i,:);
  ids = ids(ids > 0);
  girder_level(ids) = data{i,5};
end

return
end

%--------------------------------------------------------------------------
function [girder_phiI, girder_phiAs] = set_girder_phi_block(dbc, com)
data = dbc.get_data_block('梁の剛度増減率');
n = size(data,1);

% 共通配列
member_girder = com.member.girder;
baseline = com.baseline;
% story = com.story;

% データ読み取り
story_name = cell(n,2);
frame_name = cell(n,2);
coord_name = cell(n,2);
for i=1:n
  story_name(i,:) = tochar(data(i,1:2));
  frame_name(i,:) = tochar(data(i,3:4));
  coord_name(i,:) = tochar(data(i,5:6));
end

% 通り番号・方向
[idx, idy, idz, idir] = find_idxyz_girder(story_name, ...
  frame_name, coord_name, baseline);

% 梁の剛度増減率
nmeg = size(member_girder,1);
girder_phiI = nan(nmeg,1);
girder_phiAs = nan(nmeg,1);
ncol = size(data,2);
for i=1:n
  % 梁部材番号
  idmeg = find_idgirder_from_idxyz(idx(i,:), idy(i,:), ...
    idz(i,:), member_girder, idir(i), baseline);

  % 存在しないときはスキップ
  ids = idmeg(idmeg > 0);
  if isempty(ids); continue; end

  % 値のセット
  valI = data{i,8};
  girder_phiI(ids) = valI;
  has_phiAs = ncol >= 9 && ~isempty(data{i,9}) && ~isnan(data{i,9});
  if has_phiAs
    girder_phiAs(ids) = data{i,9};
  end
end
return
end

%--------------------------------------------------------------------------
function column_phi = set_member_column_phi_block(dbc, com)
data = dbc.get_data_block('柱の剛度増減率');
n = size(data,1);

% 共通配列
member_column = com.member.column;
baseline = com.baseline;
story = com.story;
% node = com.node;
% x = node.x;
% y = node.y;
% z = node.z;

% 階名
floor_name = cell(n,2);
for i=1:n
  floor_name(i,:) = tochar(data(i,1:2));
end

% 通り名
xcoord_name = cell(n,2);
ycoord_name = cell(n,2);
for i=1:n
  xcoord_name(i,:) = tochar(data(i,3:4));
  ycoord_name(i,:) = tochar(data(i,5:6));
end

% 通り番号・方向
[idx, idy, idz] = find_idxyz_column(floor_name, xcoord_name, ...
  ycoord_name, baseline, story);

% 柱の剛度増減率
nmec = size(member_column,1);
column_phi = ones(nmec,2);
for i=1:n
  dir = data{i,7};

  % 方向
  switch dir
    case "X方向"
      idir = PRM.X;
    case "Y方向"
      idir = PRM.Y;
    case "X"
      idir = PRM.X;
    case "Y"
      idir = PRM.Y;
    otherwise
      continue
  end

  % 柱部材番号
  idmec = find_idcolumn_from_idxyz(idx(i,:), idy(i,:), idz(i,:), ...
    member_column);

  % 値のセット
  val = data{i,8};
  column_phi(idmec,idir) = val;
end
return
end

%--------------------------------------------------------------------------
function factor_J = set_factor_J_girder_block(dbc, com, factor_J)
%set_factor_J_girder_block - 梁の捩り剛性増減率を factor_J に書き込む
%
%   factor_J = set_factor_J_girder_block(dbc, com, factor_J) は、
%   入力セクション「梁の捩り剛性増減率」を読み、該当梁の
%   com.member.property.factor_J に増減率を上書きして返す。
%   セクション無または空の場合は factor_J をそのまま返す。
%
%   入力引数:
%     dbc      - データブロッククラス
%     com      - 共通オブジェクト
%     factor_J - 現在の factor_J 配列 [nm×1]
%
%   出力引数:
%     factor_J - 更新後の factor_J 配列 [nm×1]

data = dbc.get_data_block('梁の捩り剛性増減率');
n = size(data,1);
if n == 0, return; end

% 共通配列
member_girder = com.member.girder;
baseline = com.baseline;

% データ読み取り（列: 層,層,フレーム,フレーム,軸,軸,増減率）
story_name = cell(n,2);
frame_name = cell(n,2);
coord_name = cell(n,2);
for i=1:n
  story_name(i,:) = tochar(data(i,1:2));
  frame_name(i,:) = tochar(data(i,3:4));
  coord_name(i,:) = tochar(data(i,5:6));
end

% バッチ呼び出し（iorigin で展開後の行と元入力行の対応を取る）
[idx, idy, idz, idir, ~, iorigin] = find_idxyz_girder( ...
  story_name, frame_name, coord_name, baseline);
for io = 1:length(idir)
  idmeg = find_idgirder_from_idxyz(idx(io,:), idy(io,:), ...
    idz(io,:), member_girder, idir(io), baseline);
  ids = idmeg(idmeg > 0);
  if isempty(ids); continue; end
  % 梁 idmeg → property 行 index（idme）へ変換して上書き
  factor_J(member_girder.idme(ids)) = data{iorigin(io),7};
end
return
end

%--------------------------------------------------------------------------
function factor_J = set_factor_J_column_block(dbc, com, factor_J)
%set_factor_J_column_block - 柱の捩り剛性増減率を factor_J に書き込む
%
%   factor_J = set_factor_J_column_block(dbc, com, factor_J) は、
%   入力セクション「柱の捩り剛性増減率」を読み、該当柱の
%   com.member.property.factor_J に増減率を上書きして返す。
%   セクション無または空の場合は factor_J をそのまま返す。
%
%   入力引数:
%     dbc      - データブロッククラス
%     com      - 共通オブジェクト
%     factor_J - 現在の factor_J 配列 [nm×1]
%
%   出力引数:
%     factor_J - 更新後の factor_J 配列 [nm×1]

data = dbc.get_data_block('柱の捩り剛性増減率');
n = size(data,1);
if n == 0, return; end

% 共通配列
member_column = com.member.column;
baseline = com.baseline;
story = com.story;

% データ読み取り（列: 階,階,X軸,X軸,Y軸,Y軸,増減率）
floor_name = cell(n,2);
xcoord_name = cell(n,2);
ycoord_name = cell(n,2);
for i=1:n
  floor_name(i,:) = tochar(data(i,1:2));
  xcoord_name(i,:) = tochar(data(i,3:4));
  ycoord_name(i,:) = tochar(data(i,5:6));
end

% 通り番号（find_idxyz_column は入力 n 行に対して n 行出力）
[idx, idy, idz] = find_idxyz_column(floor_name, xcoord_name, ...
  ycoord_name, baseline, story);

% 該当柱の factor_J を上書き
for i=1:n
  idmec = find_idcolumn_from_idxyz(idx(i,:), idy(i,:), idz(i,:), ...
    member_column);
  ids = idmec(idmec > 0);
  if isempty(ids); continue; end
  val = data{i,7};
  % 柱 idmec → property 行 index（idme）へ変換して上書き
  factor_J(member_column.idme(ids)) = val;
end
return
end

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function istarget = set_exclusion_girder_stress_block(dbc, com)
data = dbc.get_data_block('断面算定の省略（梁符号毎）');
n = size(data,1);

% 共通配列
nsecg = com.nsecg;

% 層名・通り名・方向
section_name = cell(n,1);
TF = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,1});
  TF{i} = tochar(data{i,2});
end

% 除外断面の検索
istarget = true(nsecg,1);
for i=1:n
  istarget_ = matches(com.section.girder.name, section_name{i});
  if TF{i}=='F'
    istarget(istarget_) = false;
  end
end

return
end

%--------------------------------------------------------------------------
function istarget = set_exclusion_column_stress_block(dbc, com)
%set_exclusion_column_stress_block - 柱の許容応力度検定除外設定
%
%   istarget = set_exclusion_column_stress_block(dbc, com) は、
%   柱断面の許容応力度検定対象フラグを返す。
%   RC柱（RCRS断面）は自動的に除外し、CSV入力で
%   F指定された柱符号も除外する。
%
%   入力引数:
%     dbc - データブロッククラスオブジェクト
%     com - 共通データ構造体
%
%   出力引数:
%     istarget - 検定対象フラグ [nsecc x 1] logical

% 共通配列
nsecc = com.nsecc;

% デフォルトは全て検定対象
istarget = true(nsecc,1);

% RC柱（RCRS断面）は自動的に除外
istarget(com.section.column.type == PRM.RCRS) = false;

% YLABIn.csv「断面算定の省略（柱符号毎）」による手動除外
data = dbc.get_data_block('断面算定の省略（柱符号毎）');
n = size(data,1);

section_name = cell(n,1);
TF = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,1});
  TF{i} = tochar(data{i,2});
end

for i=1:n
  istarget_ = matches(com.section.column.name, section_name{i});
  if TF{i}=='F'
    istarget(istarget_) = false;
  end
end

return
end

%--------------------------------------------------------------------------
function idexclusion = set_exclusion_girder_smooth_block(dbc, com)
data = dbc.get_data_block('梁せい分布除外');
n = size(data,1);

% 共通配列
baseline = com.baseline;
girder_idx = com.member.girder.idx;
girder_idy = com.member.girder.idy;
girder_idz = com.member.girder.idz;
girder_idir = com.member.girder.idir;
nmeg = com.nmeg;

% 層名・通り名・方向
story_name = cell(n,2);
xcoord_name = cell(n,2);
ycoord_name = cell(n,2);
idir = zeros(n,1);
for i=1:n
  story_name(i,:) = tochar(data(i,1:2));
  xcoord_name(i,:) = tochar(data(i,3:4));
  ycoord_name(i,:) = tochar(data(i,5:6));
  val = data{i,7};
  if ~ismissing(val)
    idir(i) = val;
  end
end

% 通り番号の検索
[idx, idy, idz] = find_idxyz_coord(story_name, xcoord_name, ...
  ycoord_name, baseline);

% 除外節点の検索
isexcluded = false(nmeg,1);
for i=1:n
  istarget = idx(i,1) <= girder_idx(:,1) & girder_idx(:,2) <= idx(i,2) ...
    & idy(i,1) <= girder_idy(:,1) & girder_idy(:,2) <= idy(i,2) ...
    & idz(i,1) <= girder_idz(:,1) & girder_idz(:,2) <= idz(i,2);
  if idir(i)>0
    istarget = istarget & girder_idir == idir(i);
  end
  isexcluded = isexcluded | istarget;
end
idexclusion = 1:nmeg;
idexclusion = idexclusion(isexcluded);

return
end

%--------------------------------------------------------------------------
function idexclusion = set_exclusion_column_diameter_gap_block(dbc, com)
data = dbc.get_data_block('柱外径差制限の除外');
n = size(data,1);

% 共通配列
baseline = com.baseline;
column_idx = com.member.column.idx;
column_idy = com.member.column.idy;
column_idz = com.member.column.idz;
nmec = com.nmec;

% 階名・通り名（方向列なし）
story_name = cell(n,2);
xcoord_name = cell(n,2);
ycoord_name = cell(n,2);
for i=1:n
  story_name(i,:) = tochar(data(i,1:2));
  xcoord_name(i,:) = tochar(data(i,3:4));
  ycoord_name(i,:) = tochar(data(i,5:6));
end

% 通り番号の検索（find_idxyz_column は全/ALL 対応済み）
[idx, idy, idz] = find_idxyz_column(story_name, xcoord_name, ...
  ycoord_name, baseline, com.story);

% 除外柱部材の検索
isexcluded = false(nmec,1);
for i=1:n
  istarget = idx(i,1)<=column_idx(:,1) & column_idx(:,2)<=idx(i,2) ...
    & idy(i,1)<=column_idy(:,1) & column_idy(:,2)<=idy(i,2) ...
    & idz(i,1)<=column_idz(:,1) & column_idz(:,2)<=idz(i,2);
  isexcluded = isexcluded | istarget;
end
idexclusion = 1:nmec;
idexclusion = idexclusion(isexcluded);

return
end

%--------------------------------------------------------------------------
function loadcase = set_loadcase_block(dbc)
data = dbc.get_data_block('荷重ケース');
n = size(data,1);

% 荷重ケース名
name = cell(n,1);
type_name = cell(n,1);
dir = zeros(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
  type_name{i} = tochar(data{i,2});
  switch type_name{i}
    case 'LT'
      dir(i) = PRM.LT;
    case 'EX+'
      dir(i) = PRM.EXP;
    case 'EX-'
      dir(i) = PRM.EXN;
    case 'EY+'
      dir(i) = PRM.EYP;
    case 'EY-'
      dir(i) = PRM.EYN;
  end
end
loadcase = table(name, type_name, dir);
return
end

%--------------------------------------------------------------------------
function fnode = set_nodal_force_block(dbc, com)
data = dbc.get_data_block('節点荷重');
n = size(data,1);

% 荷重ケース名
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

node = com.node; nnode = com.nnode;
loadcase = com.loadcase; nlc = com.nlc; iddlc = 1:nlc;
f = zeros(n,6);
fnode = zeros(nnode, 6, nlc);
lcase = zeros(n,1);
idx = zeros(n,1); iddx = 1:com.nblx;
idy = zeros(n,1); iddy = 1:com.nbly;
idz = zeros(n,1); iddz = 1:com.nblz;
idnode = zeros(n,1); iddn = 1:nnode;
for i=1:n
  lcase(i) = iddlc(matches(loadcase.name, name{i}));
  idx(i) = iddx(matches(com.baseline.x.name, tochar(data{i,3})));
  idy(i) = iddy(matches(com.baseline.y.name, tochar(data{i,4})));
  idz(i) = iddz(matches(com.baseline.z.name, tochar(data{i,2})));
  id_found = iddn((node.idx==idx(i))&(node.idy==idy(i)) ...
    &(node.idz==idz(i)));
  if isempty(id_found)
    throw_err('Input', 'NodeNotFound', i);
  end
  idnode(i) = id_found;
  f(i,:) = cell2mat(data(i,5:10));
  in = idnode(i);
  fnode(in, :, lcase(i)) = fnode(in, :, lcase(i)) + reshape(f(i,:), 1, 6);
  % 節点荷重は重心に作用するとみなし、偏心モーメントは計算しない
end

return
end

%--------------------------------------------------------------------------
function fnode = add_earthquake_force_position_mz(dbc, com, fnode)
data = dbc.get_data_block('地震力作用位置の直接入力');
if isempty(data)
  return
end

node = com.node;
story = com.story;
loadcase = com.loadcase;
used = false(com.nstory, 1);
for i=1:size(data,1)
  floor_name = tochar(data{i,1});
  rigid_name = tochar(data{i,2});
  method = tochar(data{i,3});
  if matches(method, '指定なし')
    continue
  end
  if ~matches(rigid_name, '主剛床')
    error('YLAB:Input:UnsupportedEarthquakeForcePosition', ...
      '地震力作用位置は主剛床のみ対応しています（行 %d）', i);
  end
  if ~matches(method, '絶対座標')
    error('YLAB:Input:UnsupportedEarthquakeForcePosition', ...
      '地震力作用位置は絶対座標のみ対応しています（行 %d）', i);
  end
  if ismissing(data{i,6}) || ismissing(data{i,7})
    error('YLAB:Input:InvalidEarthquakeForcePosition', ...
      '地震力作用位置のX座標またはY座標が空欄です（行 %d）', i);
  end

  ist = find(matches(story.floor_name, floor_name), 1);
  if isempty(ist)
    ist = find(matches(story.name, floor_name), 1);
  end
  if isempty(ist)
    error('YLAB:Input:EarthquakeForcePositionStoryNotFound', ...
      '地震力作用位置の階が見つかりません（行 %d: %s）', ...
      i, floor_name);
  end
  if used(ist)
    error('YLAB:Input:DuplicateEarthquakeForcePosition', ...
      '地震力作用位置が同じ層に複数指定されています（行 %d）', i);
  end
  used(ist) = true;

  idnode = story.idnoderep(ist);
  if isnan(idnode)
    error('YLAB:Input:EarthquakeForcePositionNodeNotFound', ...
      '地震力作用位置を反映する代表節点が見つかりません（行 %d）', i);
  end
  posx = data{i,6};
  posy = data{i,7};
  for ilc=1:com.nlc
    lcdir = loadcase.dir(ilc);
    if lcdir ~= PRM.EXP && lcdir ~= PRM.EXN ...
        && lcdir ~= PRM.EYP && lcdir ~= PRM.EYN
      continue
    end
    isnode = node.idstory == ist;
    fx = sum(fnode(isnode, 1, ilc));
    fy = sum(fnode(isnode, 2, ilc));
    mz = fx * (story.yg(ist) - posy) + fy * (posx - story.xg(ist));
    fnode(idnode, 6, ilc) = fnode(idnode, 6, ilc) + mz;
  end
end

return
end

%--------------------------------------------------------------------------
function [fnode, fnode_excl] = set_additive_nodal_force_block(dbc, com)
%set_additive_nodal_force_block - 追加節点荷重を読み込む
%   同一節点・同一ケースで2回目に出現する行（SS7変換の2巡目。片持梁
%   先端Qo相当）は等価節点荷重の帳票で非計上とするため fnode_excl に
%   分離する。fnode は解析用に全量（1巡目+2巡目）を保持する。
data = dbc.get_data_block('追加節点荷重');
n = size(data,1);

% 荷重ケース名
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

node = com.node; nnode = com.nnode;
loadcase = com.loadcase; nlc = com.nlc; iddlc = 1:nlc;
f = zeros(n,6);
fnode = zeros(nnode, 6, nlc);
fnode_excl = zeros(nnode, 6, nlc);
seen = false(nnode, nlc);
lcase = zeros(n,1);
idx = zeros(n,1); iddx = 1:com.nblx;
idy = zeros(n,1); iddy = 1:com.nbly;
idz = zeros(n,1); iddz = 1:com.nblz;
idnode = zeros(n,1); iddn = 1:nnode;
for i=1:n
  lcase(i) = iddlc(matches(loadcase.name, name{i}));
  idx(i) = iddx(matches(com.baseline.x.name, tochar(data{i,3})));
  idy(i) = iddy(matches(com.baseline.y.name, tochar(data{i,4})));
  idz(i) = iddz(matches(com.baseline.z.name, tochar(data{i,2})));
  idnode(i) = iddn((node.idx==idx(i))&(node.idy==idy(i)) ...
    &(node.idz==idz(i)));
  f(i,:) = cell2mat(data(i,5:10));
  in = idnode(i); lc = lcase(i);
  fadd = reshape(f(i,:), 1, 6);
  fnode(in, :, lc) = fnode(in, :, lc) + fadd;
  % 2回目の出現は帳票非計上分として分離（解析は全量を保持）
  if seen(in, lc)
    fnode_excl(in, :, lc) = fnode_excl(in, :, lc) + fadd;
  else
    seen(in, lc) = true;
  end
  % 剛床偏心 Mz は node_to_dof_vec で集約時に加算する
end

return
end

