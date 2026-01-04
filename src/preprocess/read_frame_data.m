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
%   cyl -> member.property(column,girder).cyl : 局所y軸（断面強軸）の方向余弦
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
labels = {...
  '基本事項', ...
  '構造計算条件', '最適化条件', '制約条件', '出力制御', ...
  '材料', '断面リスト', '柱脚リスト',  ...
  '軸X', '軸Y', '層', ...
  'スパンX方向', 'スパンY方向', '階', ...
  '剛床仮定の解除', ...
  '節点', '支点', ...
  '部材の寄り', '柱の寄り', '大梁の寄り', ...
  '軸振れ', 'セットバック', ...
  '大梁のレベル調整', '節点の同一化', ...
  '設計変数', ...
  '梁せい分布除外', ...
  'S梁断面', 'S柱断面', 'RC梁断面', 'RC柱断面', 'メーカー製柱脚断面', ...
  '鉛直ブレース断面（鋼材）', '鉛直ブレース断面（メーカー製品）', ...
  '水平ブレース断面'...
  'S梁断面(仮定)', 'S柱断面(仮定)', ...
  '鉛直ブレース断面（鋼材）(仮定)', '鉛直ブレース断面（メーカー製品）(仮定)', ...
  '大梁配置', '柱配置', '鉛直ブレース配置', '水平ブレース配置', ...
  '梁の結合状態', '柱の結合状態', '梁の横補剛', ...
  '通し柱', '通し梁', ...
  'スラブ協力幅', '柱の剛度増減率', '梁の剛度増減率'...
  '断面算定の省略（梁符号毎）', '断面算定の省略（柱符号毎）', ...
  '荷重ケース', '節点荷重', '追加節点荷重', '梁要素荷重'};
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
baseline.x.coord = calculate_coord(span.x.span);
baseline.y.coord = calculate_coord(span.y.span);
[~,iddd] = sort(floor.idz);
baseline.z.coord = calculate_coord(floor.height(iddd));
baseline.z.isdummy = story.isdummy;
baseline.z.idnominal = idstory2nominal;

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
[section_girder, variable] = ...
  set_section_steel_girder_block(dbc, com, options);
design.variable = variable;
com.design = design;
com.nvar = max((variable.idvar));
section.girder = section_girder;

%% S断面(柱)
[section_column, variable] = set_section_column_block(dbc, com);
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
[section.brace, initial_section_brace_steel] = set_initial_section_brace_steel_block(dbc, com);
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
member_horizontal_brace = ...
  set_member_horizontal_brace_block(dbc, com, options);
member.horizontal_brace = member_horizontal_brace;
com.member = member;
[gcxl, gcyl, ccxl, ccyl, bcxl, bcyl, hbcxl, hbcyl]  = ...
  update_member_cosine(member_girder, member_column, ...
  member_brace, member_horizontal_brace, node);
member_girder.cxl = gcxl;
member_girder.cyl = gcyl;
member_column.cxl = ccxl;
member_column.cyl = ccyl;
member_brace.cxl = bcxl;
member_brace.cyl = bcyl;
member_horizontal_brace.cxl = hbcxl;
member_horizontal_brace.cyl = hbcyl;
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
[section_column_base, idme2seccb] = set_section_column_base_block(dbc, com);
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
girder_phiI = set_member_girder_phi_block(dbc, com);
com.member.girder.phiI = girder_phiI;

%% 断面算定の省略（梁符号毎）
istarget = set_exclusion_girder_stress_block(dbc, com);
com.exclusion.is_section_girder_allowable_stress = istarget;

%% 断面算定の省略（柱符号毎）
istarget = set_exclusion_column_stress_block(dbc, com);
com.exclusion.is_section_column_allowable_stress = istarget;

%% 梁せい分布除外
idexclusion = set_exclusion_girder_smooth_block(dbc, com);
com.exclusion.girder_smooth.idme = idexclusion;

%% 荷重ケース
loadcase = set_loadcase_block(dbc);
com.loadcase = loadcase;
com.nlc = size(loadcase,1);

%% 節点荷重
fnode = set_nodal_force_block(dbc, com);

%% 追加節点荷重
faddnode = set_additive_nodal_force_block(dbc, com);

%% 要素荷重
[felement, ar, M0] = set_girder_force_block(dbc, com);

%% 等価節点荷重ベクトル
feqvec = fnode+faddnode-felement;
com.feqvec = feqvec;
com.fnode = fnode;
com.faddnode = faddnode;
com.felement = felement;
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
nmax = PRM.MAX_NVAR;
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
F = zeros(n,1);
isSN = false(n,1);
for i = 1:n
  id(i) = i;
  name{i} = tochar(data{i,1});
  E(i) = data{i,2};
  pr(i) = data{i,3};
  F(i) = data{i,4};
  if length(name{i})>=2
    isSN(i) = name{i}(1:2)=="SN";
  end
end

% 結果の保存
material = table(id, name, E, pr, F, isSN);
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
  val = data{i,7};
  if ismissing(val)
    idphase_(i) = 1;
  else
    idphase_(i) = val;
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
    idmaterial_(i) = iddd(matches(com.material.name, material_name_{i}));
    isSN_(i) = com.material.isSN(idmaterial_(i));
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
    design_stress_factor(i,j) = design_stress_factor_(target(j));
    isSN(i,j) = isSN_(target(j));
    idphase(i,j) = idphase_(target(j));
    type_name(i,j) = type_name_(target(j));
  end
end

% 結果の保存
section_list = section_list.registerList(...
  section_type, section_type_name, nlist, ...
  section_list_name, material_name, ...
  file_name, idmaterial, cost_factor, design_stress_factor, ...
  isSN, idphase, type_name);
return
end

%--------------------------------------------------------------------------
function column_base_list = set_column_base_list_block(dbc, input, ~)
data = dbc.get_data_block('柱脚リスト');
n = size(data,1);

% 符号・材料・リストファイル名
column_base_list(1:n) = struct(...
  'D', [], 'kbs', [], 'Df', [], 'type', [], 'name', [],...
  'list_name', [], 'list_dir', [], 'file_name', []);

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
function xbaseline = set_xbaseline_block(dbc)
data = dbc.get_data_block('軸X');
n = size(data,1);
name = cell(n,1);
id = nan(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
  id(i) = data{i,2};
end

% 結果の保存
isdummy = false(n,1);
xbaseline = table(name, id, isdummy);
xbaseline = sortrows(xbaseline, 'id');
xbaseline.id = [];
return
end

%--------------------------------------------------------------------------
function ybaseline = set_ybaseline_block(dbc)
data = dbc.get_data_block('軸Y');
n = size(data,1);
name = cell(n,1);
id = nan(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
  id(i) = data{i,2};
end

% 結果の保存
isdummy = false(n,1);
ybaseline = table(name, id, isdummy);
ybaseline = sortrows(ybaseline, 'id');
ybaseline.id = [];
return
end

%--------------------------------------------------------------------------
function xspan = set_xspan_block(dbc, com)
data = dbc.get_data_block('スパンX方向');
n = size(data,1);
name = cell(n,1);
standard_span = zeros(n,1);
span = zeros(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
  standard_span(i) = data{i,2};
  span(i) = data{i,3};
end

% 通り番号
idx = zeros(n,1); iddx = 1:com.nblx;
for i=1:n
  idx(i) = iddx(matches(com.baseline.x.name, name{i}));
end
xspan = table(name, standard_span, span, idx);
return
end

%--------------------------------------------------------------------------
function yspan = set_yspan_block(dbc, com)
data = dbc.get_data_block('スパンY方向');
n = size(data,1);
name = cell(n,1);
standard_span = zeros(n,1);
span = zeros(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
  standard_span(i) = data{i,2};
  span(i) = data{i,3};
end

% 通り番号
idy = zeros(n,1); iddy = 1:com.nbly;
for i=1:n
  idy(i) = iddy(matches(com.baseline.y.name, name{i}));
end
yspan = table(name, standard_span, span, idy);
return
end

%--------------------------------------------------------------------------
function [story, zbaseline] = set_story_block(dbc)
data = dbc.get_data_block('層');
n = size(data,1);
name = cell(n,1);
idz = nan(n,1);
isrigid = true(n,1);
xg = zeros(n,1);
yg = zeros(n,1);
girder_level = zeros(n,1);
isdummy = false(n,1);
id_dependent_story = zeros(n,1);

% 層データの読み込み
for i=1:n
  name{i} = tochar(data{i,1});
  idz(i) = data{i,2};
  isrigid(i) = (data{i,3}=='T');
  xg(i) = data{i,4};
  yg(i) = data{i,5};
  if ~ismissing(data{i,6})
    girder_level(i) = data{i,6};
  end
  if ~ismissing(data{i,7})
    if data{i,7}=='T'
      isdummy(i) = true;
    end
  end
end

% ダミー層の処理
for i=1:n
  if ~isdummy(i)
    continue
  end
  if ~ismissing(data{i,8})
    switch data{i,8}
      case '上層'
        id_dependent_story(i) = idz(i)+1;
      case '下層'
        id_dependent_story(i) = idz(i)-1;
    end
  end
end

% 結果の保存
story = table(name, idz, isrigid, xg, yg, girder_level, ...
  isdummy, id_dependent_story);
story = sortrows(story, 'idz');
id = story.idz;
name = story.name;
idstory = (1:n)';
isdummy = story.isdummy;
zbaseline = table(id,name,idstory,isdummy);
zbaseline = sortrows(zbaseline, 'id');
zbaseline.id = [];
return
end

%--------------------------------------------------------------------------
function [floor, story] = set_floor_block(dbc, com)
data = dbc.get_data_block('階');
n = size(data,1);

% 共通定数
nstory = com.nstory;

% 共通配列
story = com.story;

% 階名・標準階高・構造階高
name = cell(n,1);
standard_height = nan(n,1);
height = nan(n,1);
story_name = cell(n,2);
for i=1:n
  name{i} = tochar(data{i,1});
  story_name(i,:) = data(i,2:3);
  standard_height(i) = data{i,3};
  height(i) = data{i,4};
  if ismissing(height(i))
    height(i) = standard_height(i);
  end
end
diff_height = zeros(n,1);

% 層番号
idstory = zeros(n,1); iddd = 1:com.nstory;
idz = zeros(n,1);
isdummy = false(n,1);
idnominal = zeros(n,1);
for i=1:n
  idstory(i) = iddd(matches(com.story.name, story_name{i}));
  idz(i) = story.idz(idstory(i));
  isdummy(i) = story.isdummy(idstory(i));
  idnominal(i) = story.idnominal(idstory(i));
end
floor = table(name, story_name, standard_height, height, diff_height, ...
  idstory, idz, isdummy, idnominal);
floor = sortrows(floor,'idz');

% 層への階情報の追加
floor_name = cell(nstory,1);
for i=1:nstory; floor_name{i} = ''; end
idfloor = nan(nstory,1);
for i=1:n
  floor_name{floor.idstory(i)} = floor.name{i};
  idfloor(floor.idstory(i)) = i;
end
story.floor_name = floor_name;
story.idfloor = idfloor;
return
end

%--------------------------------------------------------------------------
function alignment = set_baseline_alignment_block(dbc, com)
data = dbc.get_data_block('部材の寄り');
n = size(data,1);

% 共通定数
nblx = com.nblx;
nbly = com.nbly;

% データ読み取り
xy_frame_name = cell(n,1);
alignment_column = zeros(n,1);
alignment_girder = zeros(n,1);
for i=1:n
  xy_frame_name{i} = tochar(data{i,1});
  alignment_column(i) = data{i,2};
  alignment_girder(i) = data{i,3};
end

% 通り番号の検索
idir = zeros(n,1);
idxy = zeros(n,1); iddd = 1:max([nblx nbly]);
for i=1:n
  % X通り
  idx = matches(com.baseline.x.name, xy_frame_name{i});
  if any(idx)
    idir(i) = PRM.X;
    idxy(i) = iddd(idx);
    continue
  end

  % Y通り
  idy = matches(com.baseline.y.name, xy_frame_name{i});
  if any(idy)
    idir(i) = PRM.Y;
    idxy(i) = iddd(idy);
  end
end

% X方向
idx = idxy(idir==PRM.X);
% frame_name = cell(nblx,1);
frame_name = com.baseline.x.name;
column = zeros(nblx,1);
girder = zeros(nblx,1);
% frame_name(idx) = xy_frame_name(idir==PRM.X);
column(idx) = alignment_column(idir==PRM.X);
girder(idx) = alignment_girder(idir==PRM.X);
x = table(frame_name, column, girder);

% Y方向
idy = idxy(idir==PRM.Y);
% frame_name = cell(nbly,1);
frame_name = com.baseline.y.name;
column = zeros(nbly,1);
girder = zeros(nbly,1);
% frame_name(idy) = xy_frame_name(idir==PRM.Y);
column(idy) = alignment_column(idir==PRM.Y);
girder(idy) = alignment_girder(idir==PRM.Y);
y = table(frame_name, column, girder);

% 結果の保存
alignment.x = x;
alignment.y = y;
return
end

%--------------------------------------------------------------------------
function alignment_column = set_baseline_alignment_column_block(dbc, com)
data = dbc.get_data_block('柱の寄り');
n = size(data,1);

% データ読み取り
story_name = cell(n,1);
xcoord_name = cell(n,1);
ycoord_name = cell(n,1);
dx = zeros(n,1);
dy = zeros(n,1);
for i=1:n
  story_name{i} = tochar(data{i,1});
  xcoord_name{i} = tochar(data{i,2});
  ycoord_name{i} = tochar(data{i,3});
  val = data{i,4};
  if ~ismissing(val)
    dx(i) = val;
  end
  val = data{i,5};
  if ~ismissing(val)
    dy(i) = val;
  end
end

% 通り番号の検索
[idx, idy, idz] = find_idxy_floor_coord(...
  story_name, xcoord_name, ycoord_name, com.baseline, com.floor);

% 結果の保存
column = table(idx, idy, idz, dx, dy);
alignment_column = column;
return
end

%--------------------------------------------------------------------------
function baseline_delta = set_baseline_delta_block(dbc, com)
data = dbc.get_data_block('軸振れ');
n = size(data,1);

% 共通定数
nblx = com.nblx;
nbly = com.nbly;

% データ読み取り
xname = cell(n,1);
yname = cell(n,1);
dx = zeros(n,1);
dy = zeros(n,1);
for i=1:n
  xname{i} = tochar(data{i,1});
  yname{i} = tochar(data{i,2});
  dx(i) = data{i,3};
  dy(i) = data{i,4};
end

% 通り番号の検索
idx = zeros(n,1);
idy = zeros(n,1);
iddd = 1:max([nblx nbly]);
for i=1:n
  % X通り
  id = matches(com.baseline.x.name, xname{i});
  if any(id)
    idx(i) = iddd(id);
  end

  % Y通り
  id = matches(com.baseline.y.name, yname{i});
  if any(id)
    idy(i) = iddd(id);
  end
end

% 結果の保存
baseline_delta = table(xname, yname, dx, dy, idx, idy);
return
end

%--------------------------------------------------------------------------
function baseline_setback = set_baseline_setback_block(dbc, com)
data = dbc.get_data_block('セットバック');
n = size(data,1);

% 共通定数
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% データ読み取り
story_name = cell(n,1);
xname = cell(n,1);
yname = cell(n,1);
dx = zeros(n,1);
dy = zeros(n,1);
for i=1:n
  story_name{i} = tochar(data{i,1});
  xname{i} = tochar(data{i,2});
  yname{i} = tochar(data{i,3});
  dx(i) = data{i,4};
  dy(i) = data{i,5};
end

% 通り番号の検索
idx = zeros(n,1);
idy = zeros(n,1);
idstory = zeros(n,1);
iddd = 1:max([nblx nbly nstory]);
for i=1:n
  % 層
  id = matches(com.story.name, story_name{i});
  if any(id)
    idstory(i) = iddd(id);
  end

  % X通り
  id = matches(com.baseline.x.name, xname{i});
  if any(id)
    idx(i) = iddd(id);
  end

  % Y通り
  id = matches(com.baseline.y.name, yname{i});
  if any(id)
    idy(i) = iddd(id);
  end
end

% 結果の保存
baseline_setback = table(...
  story_name, xname, yname, dx, dy, idstory, idx, idy);
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
  idnode(i) = iddn(com.node.idx==idx(i) & ...
    com.node.idy==idy(i) & ...
    com.node.idstory==idstory(i));
end

% 結果の保存
support = table(xname, yname, story_name, isfixed, idx, idy, idstory, idnode);
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
  idn_ = iddn(com.node.idx==idx(i) & ...
    com.node.idy==idy(i) & ...
    com.node.idstory==idstory(i));
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
flex_diaphragm = table(xname, yname, story_name, isflex, idx, idy, idstory, idnode);
return
end

%--------------------------------------------------------------------------
function [section_girder, design_variable] = ...
  set_section_steel_girder_block(dbc, com, options)
% idvar <- (Hn,Bn,twn,tfm)

data = dbc.get_data_block('S梁断面');
n = size(data,1);
design_variable = com.design.variable;

% % 有効行のチェック
% istarget = true(1,n);
% for i=1:n
%   if ismissing(data{i,4})
%     istarget(i) = false;
%   end
% end

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
idznominal = com.baseline.z.idnominal(idz);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
subindex = cell(n,1);
for i=1:n
  subindex{i} = data{i,3};
  if subindex{i}=='-'
    subindex{i} = num2str(idstory(i));
  end
  if isnumeric(subindex{i})
    subindex{i} = num2str(subindex{i});
  end
end

% 断面リスト
section_list_name = cell(n,1);
full_name = cell(n,1);
id_section_list = zeros(n,1); iddd = 1:com.nsectionList;
idmaterial = zeros(n,1);
type = zeros(n,1);
type_name = cell(n,1);
for i=1:n
  section_list_name{i} = tochar(data{i,4});
  full_name{i} = [subindex{i} name{i}];
  % fprintf('%d:%s\n',i,section_list_name{i})
  issl = strcmp(com.sectionList.name, section_list_name{i});
  if any(issl)
    idsl = iddd(issl);
    id_section_list(i) = idsl(1);
  else
    error('断面リスト %s が見つかりません (梁断面)', section_list_name{i});
  end

  % 同一の鉄骨形状のみ複数リスト指定可
  type_ = unique(com.sectionList.section_type(idsl));
  if length(type_)~=1
    error('同一断面リストに対する鉄骨形状は同一としてください')
  end
  type(i) = com.sectionList.section_type(idsl(1));
  type_name(i) = com.sectionList.section_type_name(idsl(1));
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
variable = cell(n,mvar);
idvar = zeros(n,mvar);
iddd = 1:PRM.MAX_NVAR;
nvar = com.nvar;
nvrows = sum(~isnan(design_variable.isvar));
for i=1:n
  ndvar = PRM.nvar_of_section_type(type(i));
  cdata = data(i,5:(4+ndvar));
  variable(i,1:ndvar) = tochar(cdata);
  for j=1:ndvar
    idvar_ = iddd(matches(design_variable.name, variable{i,j}));
    if isempty(idvar_)
      % 変数追加
      nvrows = nvrows+1;
      nvar = nvar+1;
      design_variable.name{nvrows} = variable{i,j};
      design_variable.isvar(nvrows) = true;
      design_variable.idvar(nvrows) = nvar;
      idvar_ = nvar;
    end
    idvar(i,j) = idvar_(1);
  end
end

% 寸法指定
dimension = zeros(n,mvar);

% 部材種別
rank = options.coptions.rank_girder*ones(n,1);
for i=1:n
  cdata = data{i,9};
  if ~ismissing(cdata)
    cdata = tochar(cdata);
    switch cdata
      case 'FA'
        rank(i) = PRM.GIRDER_RANK_FA;
      case 'FB'
        rank(i) = PRM.GIRDER_RANK_FB;
      case 'FC'
        rank(i) = PRM.GIRDER_RANK_FC;
      case 'FD'
        rank(i) = PRM.GIRDER_RANK_FD;
    end
  end
end

% 結果の保存
section_girder = table(name, subindex , story_name, full_name, ...
  id_section_list, type_name, idstory, type, idmaterial, ...
  idz, idznominal, ...
  idvar, rank, dimension);
% section_girder = table(name, subindex , story_name, full_name, ...
%   id_section_list, type_name, idstory, type, idz, idvar, dimension);
return
end

%--------------------------------------------------------------------------
function section_girder = set_section_rc_girder_block(dbc, com)
% idvar <- (Hn,Bn,twn,tfm)

data = dbc.get_data_block('RC梁断面');
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
idznominal = com.baseline.z.idnominal(idz);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
subindex = cell(n,1);
for i=1:n
  subindex{i} = data{i,3};
  if isnumeric(subindex{i})
    subindex{i} = num2str(subindex{i});
  elseif subindex{i} =='-'
    subindex{i} ='';
  end
end

% 断面リスト
full_name = cell(n,1);
idmaterial = zeros(n,1);
id_section_list = zeros(n,1);
type = zeros(n,1);
type_name = cell(n,1);
iddd = 1:com.nma;
for i=1:n
  full_name{i} = [subindex{i} name{i}];
  idmaterial(i) = iddd(matches(com.material.name, data{i,6}));
  type(i) = PRM.RCRS;
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);

% 寸法指定
dimension = zeros(n,mvar);
for i=1:n
  % b×D(1:2)
  dimension(i,1:2) = [data{i,4} data{i,5}];
  % 荷重剛性用b×D(3:4)
  dimension(i,3:4) = dimension(i,1:2);
  if data{i,7}>0
    dimension(i,3) = data{i,7};
  end
  if data{i,8}>0
    dimension(i,4) = data{i,8};
  end
end

% 部材種別
rank = zeros(n,1);

% 結果の保存
section_girder = table(name, subindex , story_name, full_name, ...
  id_section_list, type_name, idstory, type, idmaterial, ...
  idz, idznominal, ...
  idvar, dimension, rank);
return
end

%--------------------------------------------------------------------------
function section_column = set_section_column_rc_block(dbc, com)
% RC柱断面データの読み込み（set_section_rc_girder_blockを参考）

data = dbc.get_data_block('RC柱断面');
if isempty(data)
  % RC柱断面がない場合は空のテーブルを返す
  section_column = table();
  return;
end

n = size(data,1);

% 階名
floor_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
end

% 層番号（S柱断面と同じ方法）
idstory = zeros(n,1);
iddd = 1:com.nstory;
for i=1:n
  idx = strcmp(com.story.floor_name, floor_name{i});
  if any(idx)
    idstory(i) = iddd(idx);
  else
    error('階 %s が見つかりません (RC柱断面)', floor_name{i});
  end
end
idznominal = com.baseline.z.idnominal(idstory);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
subindex = cell(n,1);
for i=1:n
  subindex{i} = data{i,3};
  if isnumeric(subindex{i})
    subindex{i} = num2str(subindex{i});
  elseif subindex{i} =='-'
    subindex{i} ='';
  end
end

% 断面リスト
full_name = cell(n,1);
idmaterial = zeros(n,1);
id_section_list = zeros(n,1);  % 最適化対象外
type = zeros(n,1);
type_name = cell(n,1);
iddd = 1:com.nma;
for i=1:n
  full_name{i} = [subindex{i} name{i}];
  idmaterial(i) = iddd(matches(com.material.name, data{i,7}));
  type(i) = PRM.RCRS;  % RC矩形断面
  type_name{i} = 'RCRS';
end

% 設計変数番号（最適化対象外のため0）
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);

% 寸法指定
dimension = zeros(n,mvar);
for i=1:n
  % Dx×Dy（形状は□なので正方形または矩形）
  dimension(i,1:2) = [data{i,5} data{i,6}];
  % 荷重剛性用Dx×Dy
  dimension(i,3:4) = dimension(i,1:2);
  if ~ismissing(data{i,8}) && data{i,8}>0
    dimension(i,3) = data{i,8};
  end
  if ~ismissing(data{i,9}) && data{i,9}>0
    dimension(i,4) = data{i,9};
  end
end

% 部材種別
rank = zeros(n,1);

% 結果の保存（S柱断面と同じテーブル構造）
section_column = table(name, subindex, full_name, floor_name, ...
  id_section_list, type_name, idstory, type, idmaterial, ...
  idznominal, idvar, dimension);

return
end

%--------------------------------------------------------------------------
function [section_column, design_variable] = ...
  set_section_column_block(dbc, com)

data = dbc.get_data_block('S柱断面');
n = size(data,1);
design_variable = com.design.variable;

% 階名
% TODO: 要確認
floor_name = cell(n,1);
for i=1:n
  if ~ischar(data{i,1})
    val = tochar(data{i,1});
  else
    val = data{i,1};
  end
  floor_name{i} = tochar(val);
end

% 層番号
idstory = zeros(n,1); iddd = 1:com.nstory;
for i=1:n
  idstory(i) = iddd(matches(com.story.floor_name, floor_name{i}));
end
idznominal = com.baseline.z.idnominal(idstory);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
subindex = cell(n,1);
for i=1:n
  subindex{i} = data{i,3};
  if isnumeric(subindex{i})
    subindex{i} = num2str(subindex{i});
  end
end

% 断面リスト
section_list_name = cell(n,1);
full_name = cell(n,1);
id_section_list = zeros(n,1); iddd = 1:com.nsectionList;
idmaterial = zeros(n,1);
type = zeros(n,1);
type_name = cell(n,1);
for i=1:n
  full_name{i} = [subindex{i} name{i}];
  section_list_name{i} = tochar(data{i,4});
  idx = strcmp(com.sectionList.name, section_list_name{i});
  if any(idx)
    idsl = iddd(idx);
    id_section_list(i) = idsl(1);
  else
    error('断面リスト %s が見つかりません (柱断面)', section_list_name{i});
  end

  % 同一の鉄骨形状のみ複数リスト指定可
  type_ = unique(com.sectionList.section_type(idsl));
  if length(type_)~=1
    error('同一断面リストに対する鉄骨形状は同一としてください')
  end
  type(i) = com.sectionList.section_type(idsl(1));
  type_name(i) = com.sectionList.section_type_name(idsl(1));
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
variable = cell(n,mvar);
idvar = zeros(n,mvar);
iddd = 1:PRM.MAX_NVAR;
nvar = com.nvar;
nvrows = sum(~isnan(design_variable.isvar));
for i=1:n
  ndvar = PRM.nvar_of_section_type(type(i));
  cdata = data(i,5:(4+ndvar));
  variable(i,1:ndvar) = tochar(cdata);
  for j=1:ndvar
    idvar_ = iddd(matches(design_variable.name, variable{i,j}));
    if isempty(idvar_)
      % 変数追加
      nvrows = nvrows+1;
      nvar = nvar+1;
      design_variable.name{nvrows} = variable{i,j};
      design_variable.isvar(nvrows) = true;
      design_variable.idvar(nvrows) = nvar;
      idvar_ = nvar;
    end
    idvar(i,j) = idvar_(1);
  end
end

% 寸法指定（断面リストから取得するためゼロで初期化）
dimension = zeros(n,mvar);

% 結果の保存
section_column = table(name, subindex, full_name, floor_name,  ...
  id_section_list, type_name, idstory, type, idmaterial, ...
  idznominal, idvar, dimension);
% section_column = table(name, subindex, full_name, floor_name,  ...
%   id_section_list, type_name, idstory, type, idvar);
return
end

%--------------------------------------------------------------------------
function [column_base, idme2seccb] = set_section_column_base_block(dbc, com)
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
  name = data{i,3};
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
  idme2seccb(idm2sc==idsc&idm2story==2&idm2ctype==PRM.COLUMN_FOR_BRACE2) = i;
  % idme2seccb(idm2sc==idsc&idm2story==2&idm2ctype==PRM.COLUMN_FOR_BRACE) = i;
  % idme2seccb(idm2sc==idsc&idm2z==1) = i;
end

% 結果の保存
% column_base = table(floor_name, coord_name, section_name, ...
%   type, property, idlist, idstory, idx, idy, idz, idsecc, idmec, idme);
column_base = table(floor_name, section_name, ...
  type, property, idlist, idstory, idsecc);
return
end

%--------------------------------------------------------------------------
function [section_brace, design_variable] = ...
  set_section_vertical_brace_steel_block(dbc, com)

% データ取得
data = dbc.get_data_block('鉛直ブレース断面（鋼材）');
n = size(data,1);
design_variable = com.design.variable;

% ブレース符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

% 断面リスト
section_list_name = cell(n,1);
id_section_list = zeros(n,1);
iddd = 1:com.nsectionList;
type = zeros(n,1);
type_name = cell(n,1);

for i=1:n
  section_list_name{i} = tochar(data{i,2});
  idx = strcmp(com.sectionList.name, section_list_name{i});
  if any(idx)
    idsl = iddd(idx);
    id_section_list(i) = idsl(1);
  else
    error('断面リスト %s が見つかりません (鉛直ブレース断面（鋼材）)', ...
      section_list_name{i});
  end
  type(i) = com.sectionList.section_type(id_section_list(i));
  type_name{i} = com.sectionList.section_type_name{id_section_list(i)};
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
variable = cell(n,mvar);
idvar = zeros(n,mvar);
iddd = 1:PRM.MAX_NVAR;
nvar = com.nvar;
nvrows = sum(~isnan(design_variable.isvar));

for i=1:n
  ndvar = PRM.nvar_of_section_type(type(i));
  cdata = data(i,3:(2+ndvar));
  variable(i,1:ndvar) = tochar(cdata);
  for j=1:ndvar
    idvar_ = iddd(matches(design_variable.name, variable{i,j}));
    if isempty(idvar_)
      % 変数追加
      nvrows = nvrows+1;
      nvar = nvar+1;
      design_variable(nvrows,:) = {variable{i,j}, 0, false, nvar};
      idvar_ = nvar;
    end
    idvar(i,j) = idvar_(1);
  end
end

% 寸法指定（断面リストから取得するためゼロで初期化）
dimension = zeros(n,mvar);

% 断面特性（断面リストから取得）
A = zeros(n,1);
E = zeros(n,1);
unit_weight = zeros(n,1);
ir = zeros(n,1);    % 回転半径
lmbe = zeros(n,1);  % 有効細長比

% 引張/圧縮タイプ（デフォルト：引張圧縮）
tctype = zeros(n,1);
tctype(1:n) = PRM.BRACE_TENSION_COMPRESSION;

% 結果テーブル
section_brace = table(name, id_section_list, type_name, type, tctype, ...
  idvar, A, E, unit_weight, ir, lmbe, dimension);

return
end

%--------------------------------------------------------------------------
function [section_brace, design_variable] = ...
  set_section_vertical_brace_manufacturer_block(dbc, com)

% 計算の準備
data = dbc.get_data_block('鉛直ブレース断面（メーカー製品）');
n = size(data,1);
design_variable = com.design.variable;

% 断面符号
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,1});
end

% 断面リスト
section_list_name = cell(n,1);
id_section_list = zeros(n,1); iddd = 1:com.nsectionList;
type = zeros(n,1);
type_name = cell(n,1);
for i=1:n
  section_list_name{i} = tochar(data{i,2});
  idx = strcmp(com.sectionList.name, section_list_name{i});
  if any(idx)
    idsl = iddd(idx);
    id_section_list(i) = idsl(1);
  else
    error('断面リスト %s が見つかりません (ブレース断面)', section_list_name{i});
  end
  % 同一の鉄骨形状のみ複数リスト指定可
  type_ = unique(com.sectionList.section_type(idsl));
  if length(type_)~=1
    error('同一断面リストに対する鉄骨形状は同一としてください')
  end
  type(i) = com.sectionList.section_type(idsl(1));
  type_name(i) = com.sectionList.section_type_name(idsl(1));
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
variable = cell(n,mvar);
idvar = zeros(n,mvar);
iddd = 1:PRM.MAX_NVAR;
nvar = com.nvar;
nvrows = sum(~isnan(design_variable.isvar));
for i=1:n
  ndvar = PRM.nvar_of_section_type(type(i));
  cdata = data(i,3:(2+ndvar));
  variable(i,1:ndvar) = tochar(cdata);
  for j=1:ndvar
    idvar_ = iddd(matches(design_variable.name, variable{i,j}));
    if isempty(idvar_)
      % 変数追加
      nvrows = nvrows+1;
      nvar = nvar+1;
      % % TODO:とりあえず固定
      % design_variable.name{nvrows} = variable{i,j};
      % design_variable.isvar(nvrows) = false;
      % design_variable.idvar(nvrows) = nvar;
      design_variable(nvrows,:) = {variable{i,j}, 0, false, nvar};
      idvar_ = nvar;
    end
    idvar(i,j) = idvar_(1);
  end
end

% 寸法指定（断面リストから取得するためゼロで初期化）
dimension = zeros(n,mvar);

% 結果の保存
name = section_name;
A = zeros(n,1);
E = zeros(n,1);
unit_weight = zeros(n,1);
ir = zeros(n,1);    % 回転半径
lmbe = zeros(n,1);  % 有効細長比
tctype = zeros(n,1); tctype(1:n) = PRM.BRACE_TENSION_COMPRESSION;
section_brace = table(name, id_section_list, type_name, type, tctype, ...
  idvar, A, E, unit_weight, ir, lmbe, dimension);
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
function [member_property, idmec2mem, idmeg2mem, idmeb2mem, idmehb2mem] = ...
  set_member_property(com)
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
x = com.node.x;
y = com.node.y;
z = com.node.z;

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

% 部材長さ
lm = sqrt((x(idnode2)-x(idnode1)).^2 ...
  +(y(idnode2)-y(idnode1)).^2+(z(idnode2)-z(idnode1)).^2);

% 変数番号
mvar = PRM.MAX_NSVAR;
idvar = zeros(nme,mvar);
idvar(type==PRM.COLUMN,:) = section_column.idvar(member_column.idsecc,:);
idvar(type==PRM.GIRDER,:) = section_girder.idvar(member_girder.idsecg,:);
idvar(type==PRM.BRACE,:) = section_brace.idvar(member_brace.idsecb,:);

% 部材座標軸
cxl = zeros(nme,3); cyl = zeros(nme,3);
cxl(type==PRM.GIRDER,:) = member_girder.cxl;
cyl(type==PRM.GIRDER,:) = member_girder.cyl;
cxl(type==PRM.COLUMN,:) = member_column.cxl;
cyl(type==PRM.COLUMN,:) = member_column.cyl;
cxl(type==PRM.BRACE,:) = member_brace.cxl;
cyl(type==PRM.BRACE,:) = member_brace.cyl;
cxl(type==PRM.HORIZONTAL_BRACE,:) = member_horizontal_brace.cxl;
cyl(type==PRM.HORIZONTAL_BRACE,:) = member_horizontal_brace.cyl;

% 向き
idir = zeros(nme,1);
idir(type==PRM.GIRDER) = member_girder.idir;
idir(type==PRM.BRACE) = member_brace.idir;

% 結果の保存
member_property = table(type, idir, idmeg, idmec, idmeb, idmehb, ...
  section_type, idsec, idsecc, idsecg, idsecb, idsechb, ...
  idnode1, idnode2, idstory, lm, cxl, cyl, idvar);
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
dimension(mtype==PRM.HORIZONTAL_BRACE,:) = section_horizontal_brace.dimension;

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
function initial_section_column = set_initial_section_column_block(dbc, com)
data = dbc.get_data_block('S柱断面(仮定)');
n = size(data,1);

% 階名
floor_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
end

% 層番号
idstory = zeros(n,1); iddd = 1:com.nstory;
for i=1:n
  idstory(i) = iddd(matches(com.story.floor_name, floor_name{i}));
end

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
subindex = cell(n,1);
full_name = cell(n,1);
for i=1:n
  subindex{i} = data{i,3};
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
initial_section_column = table(name, subindex , floor_name, full_name, ...
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
function member_girder = set_member_girder_block(dbc, com)
data = dbc.get_data_block('大梁配置');
n = size(data,1);

% 共通配列
section_girder = com.section.girder;
node = com.node;
x = node.x;
y = node.y;
z = node.z;

% 層名・通り名
story_name = cell(n,1);
frame_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,1});
  frame_name{i} = tochar(data{i,2});
  coord_name(i,:) = tochar(data(i,3:4));
end

% 断面符号
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,5});
end

% 断面（強軸）の角度
angle = zeros(n,1);
for i=1:n
  if ~ismissing(data{i,6})
    angle(i) = data{i,6};
  end
end

% 合成梁効果
comp_effect = zeros(n,1);
for i=1:n
  val = data{i,7};
  if ~ismissing(val)
    comp_effect(i) = val;
  end
end

% 横補剛間隔
Lb = zeros(n,1);
for i=1:n
  val = data{i,8};
  % if ~ismissing(val)
  Lb(i) = val;
  % end
end

% 反転配置
ismirrored = false(n,1);
for i=1:n
  val = tochar(data{i,9});
  if ismissing(val)
    continue
  end
  if val=='T'
    ismirrored(i) = true;
  end
end

% 層番号
idstory = zeros(n,1); idds = 1:com.nstory;
for i=1:n
  idstory(i) = idds(matches(com.story.name, story_name{i}));
end

% 通り番号・方向
[idx, idy, idz, idir, idzn] = find_idxyz_girder(...
  story_name, frame_name, coord_name, com.baseline);

% 断面番号
idsecg = zeros(n,1); iddd = 1:com.nsecg;
for i=1:n
  % id = iddd(matches(section_girder.name, section_name{i}) ...
  %   & section_girder.idz==idz(i));
  id = iddd(matches(section_girder.name, section_name{i}) ...
    & section_girder.idznominal==idzn(i,1));
  if isempty(id)
    id = iddd(matches(section_girder.full_name, section_name{i}));
  end
  idsecg(i) = id;
end

% 断面種別
section_type = section_girder.type(idsecg);

% 節点番号
idnode1 = find_idnode_from_idxyz(idx(:,1), idy(:,1), idz(:,1), node);
idnode2 = find_idnode_from_idxyz(idx(:,2), idy(:,2), idz(:,2), node);

% 変数番号
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);
for i=1:n
  idvar(i,:) = section_girder.idvar(idsecg(i),:);
end

% 方向余弦の計算
an = deg2rad(angle);
[cyl, cxl] = ystar(x(idnode1), y(idnode1), z(idnode1), ...
  x(idnode2), y(idnode2), z(idnode2), an);

% 梁タイプ（デフォルト: GIRDER_STANDARD）
type = zeros(n,1);  % GIRDER_STANDARD = 0

% 結果の保存
member_girder = table(story_name, frame_name, coord_name, ...
  section_name, section_type, type, angle, comp_effect, Lb, ismirrored, ...
  idstory, idir, idx, idy, idz, idzn, idsecg, idnode1, idnode2, ...
  cxl, cyl, idvar);

% WFS部材番号の設定
nmeg = size(member_girder,1);
idmewfs = zeros(nmeg,1);
is_wfs = (section_type == PRM.WFS);
idmewfs(is_wfs) = 1:sum(is_wfs);
member_girder.idmewfs = idmewfs;

return
end

%--------------------------------------------------------------------------
function member_horizontal_brace = ...
  set_member_horizontal_brace_block(dbc, com, options)
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

% 層番号
idstory = zeros(n,1); idds = 1:com.nstory;
for i=1:n
  idstory(i) = idds(matches(com.story.name, story_name{i}));
end

% 通り番号・方向
[idx, idy, idz] = find_idxy_story_coord(...
  story_name, xcoord_name, ycoord_name, com.baseline, com.story);

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
member_horizontal_brace = table(story_name, xcoord_name, ycoord_name, ...
  section_name, section_type, idpair, ...
  idstory, idx, idy, idz, idsechb, idnode1, idnode2, ...
  cxl, cyl);

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
[idx, idy, idz, idir] = find_idxyz_girder(...
  story_name, frame_name, coord_name, baseline);
idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder);

% 結合状態
joint = PRM.FIX*ones(nmeg,4);
for i=1:n
  for j=1:4
    val = data{i,j+4};
    im = idmeg(i);
    if ismissing(val) || im==0
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

return
end

%--------------------------------------------------------------------------
function joint = set_member_column_joint_block(dbc, com)
% 柱の結合状態を読み込む
%
% CSVデータ構造:
% 階, X軸, Y軸, 結合状態(X)柱頭, 結合状態(X)柱脚,
% 結合状態(Y)柱頭, 結合状態(Y)柱脚
% 結合状態: 0=ピン, それ以外=固定

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
  idmec = find_idcolumn_from_idxyz(idx_search(i,:), idy_search(i,:), idz_search(i,:), member_column);

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
end%--------------------------------------------------------------------------
function girder_stiffening = set_member_girder_stiffening_block(dbc, com)
data = dbc.get_data_block('梁の横補剛');
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
[idx, idy, idz, idir] = find_idxyz_girder(...
  story_name, frame_name, coord_name, baseline);
idmeg = find_idgirder_from_idxyz_range(idx, idy, idz, member_girder);

% % 結合状態
% stiffening.Lb = nan(nmeg,3);
% for i=1:n
%   ig = idmeg(i);
%   stiffening.Lb(ig,1) = data{i,6};
%   stiffening.Lb(ig,2) = data{i,7};
%   stiffening.Lb(ig,3) = data{i,8};
% end

Lb = nan(n,3);
xc = nan(n,2);
for i=1:n
  Lb1 = data{i,6};
  Lb2 = data{i,8};
  Lbmax = data{i,10};
  x1 = data{i,11};
  x2 = data{i,12};
  % if ismissing(Lb1)
  %   Lb1 = Lbmax;
  % end
  % if ismissing(Lb2)
  %   Lb2 = Lbmax;
  % end

  Lb(i,1) = Lb1;
  Lb(i,2) = Lb2;
  Lb(i,3) = Lbmax;
  xc(i,1) = x1;
  xc(i,2) = x2;
end

% 結果の保存
girder_stiffening = table(idmeg, Lb, xc);
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
[idx, idy, idz, idir] = find_idxyz_girder(...
  story_name, frame_name, coord_name, baseline);

% 梁部材番号
idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder);

% レベル調整値
girder_level = zeros(nmg,1);
for i=1:n
  if (idmeg(i)>0)
    girder_level(idmeg(i)) = data{i,5};
  end
end

return
end

%--------------------------------------------------------------------------
function member_girder = set_member_girder_slab_block(dbc, com)
data = dbc.get_data_block('スラブ協力幅');
n = size(data,1);

% 共通定数
nmg = com.nmeg;

% 共通配列
baseline = com.baseline;
material = com.material;
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

% 断面符号
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,5});
end

% 通り番号・方向
[idx, idy, idz, idir] = find_idxyz_girder(...
  story_name, frame_name, coord_name, baseline);

% 梁部材番号
idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder);

% スラブ協力幅
slab_width = zeros(nmg,2);
for i=1:n
  if (idmeg(i)>0)
    slab_width(idmeg(i),1) = data{i,6};
    slab_width(idmeg(i),2) = data{i,7};
  end
end

% スラブ厚
slab_thickness = zeros(nmg,2);
for i=1:n
  if (idmeg(i)>0)
    slab_thickness(idmeg(i),:) = data{i,8};
    if (~ismissing(data{i,10}))
      slab_thickness(idmeg(i),2) = data{i,10};
    end
  end
end

% 材料名
slab_E = zeros(nmg,1); iddd = 1:com.nma;
for i=1:n
  material_name = data{i,9};
  idmaterial = iddd(matches(material.name, material_name));
  if (idmeg(i)>0)
    slab_E(idmeg(i)) = material.E(idmaterial);
  end
end

% デッキ高さ
deck_height = zeros(nmg,2);
for i=1:n
  if (idmeg(i)>0)
    if ~ismissing(data{i,11})
      deck_height(idmeg(i),1) = data{i,11};
    end
    if ~ismissing(data{i,12})
      deck_height(idmeg(i),2) = data{i,12};
    end
  end
end

% 結果の保存
member_girder.slab_width = slab_width;
member_girder.slab_thickness = slab_thickness;
member_girder.slab_E = slab_E;
member_girder.deck_height = deck_height;

return
end
%--------------------------------------------------------------------------
function girder_phi = set_member_girder_phi_block(dbc, com)
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
[idx, idy, idz, idir] = find_idxyz_girder(...
  story_name, frame_name, coord_name, baseline);

% 柱の剛度増減率
nmeg = size(member_girder,1);
girder_phi = nan(nmeg,1);
for i=1:n
  % 梁部材番号
  idmeg = find_idgirder_from_idxyz(...
    idx(i,:), idy(i,:), idz(i,:), member_girder, idir(i));

  % 存在しないときはスキップ
  if idmeg ==0
    continue
  end

  % 値のセット
  val = data{i,8};
  girder_phi(idmeg) = val;
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
[idx, idy, idz] = find_idxyz_column(...
  floor_name, xcoord_name, ycoord_name, baseline, story);

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
  idmec = find_idcolumn_from_idxyz(...
    idx(i,:), idy(i,:), idz(i,:), member_column);

  % 値のセット
  val = data{i,8};
  column_phi(idmec,idir) = val;
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
% 柱の許容応力度検定除外設定（RC柱の自動除外）

% 共通配列
nsecc = com.nsecc;

% デフォルトは全て検定対象
istarget = true(nsecc,1);

% RC柱（RCRS断面）は自動的に除外
istarget(com.section.column.type == PRM.RCRS) = false;

% 将来的に手動除外が必要な場合はここに追加
% data = dbc.get_data_block('断面算定の省略（柱符号毎）');
% if size(data,1) > 0
%   % 手動除外処理
% end

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
[idx, idy, idz] = find_idxyz_coord(...
  story_name, xcoord_name, ycoord_name, baseline);

% 除外節点の検索
isexcluded = false(nmeg,1);
for i=1:n
  istarget = ...
    idx(i,1) <= girder_idx(:,1) ...
    & girder_idx(:,2) <= idx(i,2) ...
    & idy(i,1) <= girder_idy(:,1) ...
    & girder_idy(:,2) <= idy(i,2) ...
    & idz(i,1) <= girder_idz(:,1) ...
    & girder_idz(:,2) <= idz(i,2);
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

% 共通定数
ndf = com.ndf;

% 荷重ケース名
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

node = com.node; nnode = com.nnode;
loadcase = com.loadcase; nlc = com.nlc; iddlc = 1:nlc;
f = zeros(n,6);
fnode = zeros(ndf,nlc);
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
    throw_err('read_frame_data', 'NodeNotFound', i);
  end
  idnode(i) = id_found;
  f(i,:) = cell2mat(data(i,5:10));
  idof = node.dof(idnode(i),:);
  fnode(idof,lcase(i)) = fnode(idof,lcase(i))+f(i,:)';
  % 節点荷重は重心に作用するとみなし、偏心モーメントは計算しない
end

return
end

%--------------------------------------------------------------------------
function fnode = set_additive_nodal_force_block(dbc, com)
data = dbc.get_data_block('追加節点荷重');
n = size(data,1);

% 共通定数
ndf = com.ndf;

% 荷重ケース名
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

node = com.node; nnode = com.nnode;
story = com.story;
loadcase = com.loadcase; nlc = com.nlc; iddlc = 1:nlc;
f = zeros(n,6);
fnode = zeros(ndf,nlc);
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
  idof = node.dof(idnode(i),:);
  fnode(idof,lcase(i)) = fnode(idof,lcase(i))+f(i,:)';
  fnode = add_rigid_eccentric_moment(fnode, idnode(i), f(i,1), f(i,2), ...
    lcase(i), node, story);
end

return
end

%--------------------------------------------------------------------------
function [felement, ar, M0] = set_girder_force_block(dbc, com)
data = dbc.get_data_block('梁要素荷重');
n = size(data,1);

% 共通定数
nlc = com.nlc;
nm = com.nme;
ndf = com.ndf;

% 共通配列
baseline = com.baseline;
member_girder = com.member.girder;
js = com.member.girder.idnode1;
je = com.member.girder.idnode2;
loadcase = com.loadcase;
node = com.node;
story = com.story;
cxl = member_girder.cxl;
cyl = member_girder.cyl;
idmg2m = member_girder.idme;

% 荷重ケース名
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

% 層名・通り名
story_name = cell(n,1);

frame_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,2});
  frame_name{i} = tochar(data{i,3});
  coord_name(i,:) = tochar(data(i,4:5));
end

% 荷重ケース番号
iddlc = 1:nlc;
lcase = zeros(n,1);
for i=1:n
  lcase(i) = iddlc(matches(loadcase.name, name{i}));
end

% 通り番号・方向
[idx, idy, idz, idir] = find_idxyz_girder(...
  story_name, frame_name, coord_name, baseline);

% 梁部材番号
idmgs = find_idgirder_from_idxyz(idx, idy, idz, member_girder);

% 部材にかかる中間荷重の等価節点力の総和
ar = zeros(nm,12,nlc);
M0 = zeros(nm,nlc);

% 部材座標第3軸
czl = cross(cxl, cyl, 2);

% 要素荷重のセット
%   ※座標変換行列は[T]^Tなので注意
felement = zeros(ndf,nlc);
for i = 1:n
  idmg = idmgs(i);
  idm = idmg2m(idmg);
  if (idmg==0)
    continue
  end
  ilc = lcase(i);
  arunit = cell2mat(data(i,6:17));
  ar(idm,:,ilc) = ar(idm,:,ilc)+arunit;
  M0(idm,ilc) = M0(idm,ilc)+data{i,18};
  tt = [cxl(idmg,:)' cyl(idmg,:)' czl(idmg,:)'];
  nn = node.dof(js(idmg),:);
  fi = tt*arunit(1:3)';  % i端の荷重（全体座標系）
  felement(nn,ilc) = felement(nn,ilc) + [fi; tt*arunit(4:6)'];
  felement = add_rigid_eccentric_moment(felement, js(idmg), fi(1), fi(2), ...
    ilc, node, story);
  nn = node.dof(je(idmg),:);
  fj = tt*arunit(7:9)';  % j端の荷重（全体座標系）
  felement(nn,ilc) = felement(nn,ilc) + [fj; tt*arunit(10:12)'];
  felement = add_rigid_eccentric_moment(felement, je(idmg), fj(1), fj(2), ...
    ilc, node, story);
end

% 水平荷重は要素荷重として扱わない
% xydof = unique(reshape(node.dof(:,1:2),1,[]));
% felement(xydof,1) = 0;
return
end

%--------------------------------------------------------------------------
function fvec = add_rigid_eccentric_moment(fvec, idnode, fx, fy, ilc, ...
  node, story)
% 剛床の偏心モーメント計算
% 剛床内の節点に水平力(fx, fy)がかかった場合、重心まわりのモーメントを計算
is_ = node.idstory(idnode);
if story.isrigid(is_)
  xr_ = node.xr(idnode);
  yr_ = node.yr(idnode);
  Mz_add = fx*(-yr_) + fy*xr_;
  idof_rz = node.dof(idnode, 6);  % 代表節点のθZ自由度
  fvec(idof_rz, ilc) = fvec(idof_rz, ilc) + Mz_add;
end

return
end
