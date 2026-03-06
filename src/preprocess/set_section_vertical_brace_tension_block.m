function section_brace = ...
  set_section_vertical_brace_tension_block(dbc, com)
%set_section_vertical_brace_tension_block - 引張ブレース断面の読み込み

data = ...
  dbc.get_data_block('鉛直ブレース断面（引張ブレース）');
n = size(data,1);

if n == 0
  section_brace = table();
  return
end

% ブレース符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

% 登録形状（union_TB.csv の type 列で検索するキー）
registered_shape = cell(n,1);
for i=1:n
  registered_shape{i} = tochar(data{i,2});
end

% 断面リスト
section_list_name = cell(n,1);
id_section_list = zeros(n,1);
iddd = 1:com.nsectionList;
type = zeros(n,1);
type_name = cell(n,1);
for i=1:n
  section_list_name{i} = tochar(data{i,3});
  idx = strcmp(com.sectionList.name, ...
    section_list_name{i});
  if any(idx)
    idsl = iddd(idx);
    id_section_list(i) = idsl(1);
  else
    throw_err('SectionList', ...
      'SectionListNotFound', ...
      section_list_name{i}, ...
      '鉛直ブレース断面（引張ブレース）', ...
      ['符号: ' name{i}]);
  end
  type(i) = ...
    com.sectionList.section_type(id_section_list(i));
  type_name{i} = ...
    com.sectionList.section_type_name{ ...
      id_section_list(i)};
end

% 設計変数なし
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);

% dimension の構成:
%   列1: shape_code (形状コード)
%   列2: A (全断面積, mm2)
%   列3: Ae (有効断面積, mm2)
%   列4: Ta (許容引張力, kN)
dimension = zeros(n,mvar);
for i=1:n
  idsl = id_section_list(i);
  list_ = com.sectionList.list{idsl};
  idr = find(strcmp(list_.label, ...
    registered_shape{i}), 1);
  if isempty(idr)
    error(['引張ブレース断面 %s: ' ...
      '登録形状 %s がリスト %s に見つかりません'], ...
      name{i}, registered_shape{i}, ...
      section_list_name{i});
  end
  dimension(i,1) = ...
    PRM.get_tb_shape_code(registered_shape{i});
  dimension(i,2) = list_.A(idr) * 100;  % cm2 → mm2
  dimension(i,3) = list_.Ae(idr) * 100; % cm2 → mm2
  dimension(i,4) = list_.Ta(idr);        % kN
end

% 断面特性（BRBと同様、secdim → calc_secprop 経由）
A = zeros(n,1);
E = zeros(n,1);
unit_weight = zeros(n,1);
ir = zeros(n,1);
lmbe = zeros(n,1);

% 引張のみ
tctype = zeros(n,1);
tctype(1:n) = PRM.BRACE_TENSION;

section_brace = table(name, id_section_list, ...
  type_name, type, tctype, ...
  idvar, A, E, unit_weight, ir, lmbe, dimension);

return
end
