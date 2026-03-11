function [section_brace, design_variable] = ...
  set_section_vertical_brace_steel_block(dbc, com)
%set_section_vertical_brace_steel_block - 鋼材鉛直ブレース断面の読み込み

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

% 梁/柱が参照する断面リストIDを取得
gc_slist = unique([ ...
  com.section.girder.id_section_list; ...
  com.section.column.id_section_list]);
gc_slist = gc_slist(gc_slist > 0);

for i=1:n
  section_list_name{i} = tochar(data{i,2});
  idx = strcmp(com.sectionList.name, ...
    section_list_name{i});
  if any(idx)
    idsl = iddd(idx);
    id_section_list(i) = idsl(1);
  else
    throw_err('IO', ...
      'SectionListNotFound', ...
      section_list_name{i}, ...
      '鉛直ブレース断面（鋼材）', ...
      ['符号: ' name{i}]);
  end

  % 梁/柱との断面リスト共有チェック
  if any(gc_slist == id_section_list(i))
    throw_err('Input', 'SharedSectionList', ...
      section_list_name{i});
  end

  % 断面リストの型からブレース専用型をセット
  slist_type = com.sectionList.section_type( ...
    id_section_list(i));
  switch slist_type
    case PRM.WFS
      type(i) = PRM.BWFS;
    case PRM.HSS
      type(i) = PRM.BHSS;
    case PRM.HSR
      type(i) = PRM.BHSR;
    otherwise
      type(i) = slist_type;
  end
  com.sectionList.section_type( ...
    id_section_list(i)) = type(i);
  type_name{i} = ...
    com.sectionList.section_type_name{ ...
      id_section_list(i)};
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
    idvar_ = iddd( ...
      matches(design_variable.name, variable{i,j}));
    if isempty(idvar_)
      % 変数追加
      nvrows = nvrows+1;
      nvar = nvar+1;
      design_variable(nvrows,:) = ...
        {variable{i,j}, 0, false, nvar};
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
section_brace = table(name, id_section_list, ...
  type_name, type, tctype, ...
  idvar, A, E, unit_weight, ir, lmbe, dimension);

return
end
