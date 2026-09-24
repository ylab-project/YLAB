function [section_column, design_variable] = ...
  set_section_column_block(dbc, com, options)
%set_section_column_block - S柱断面ブロックの読み込み
%
%   [section_column, design_variable] = ...
%     set_section_column_block(dbc, com, options) は、入力データの
%   「S柱断面」ブロックを読み込み、S柱の断面情報テーブルと更新後の
%   設計変数構造体を返す。
%
%   入力引数:
%     dbc     - データブロックコンテナ
%     com     - 共通オブジェクト (story/baseline/sectionList 等)
%     options - 実行オプション (coptions.rank_column 等)
%
%   出力引数:
%     section_column  - S柱断面テーブル [n×13]
%       主要列: name, subindex, full_name, floor_name, id_section_list,
%       type_name, idstory, type, idmaterial, idznominal, idvar, rank,
%       dimension
%     design_variable - 更新された設計変数構造体
%
%   備考:
%     - subindexは添字省略を空のcharとして保持する。
%     - 第10列の鉄骨形状は、H・Ｈを柱用H形鋼のX方向強軸、I・Ｉを
%       同じくY方向強軸として断面種別（type）に保存する。省略時は
%       断面リストの鉄骨形状を継承する。type_nameは断面リストの
%       鉄骨形状名のまま保持する。
%     - 部材種別（ランク）は列9だけを読む。

data = dbc.get_data_block('S柱断面');
n = size(data,1);
ncol = size(data,2);
design_variable = com.design.variable;

% 階名
floor_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
end

% 層番号
idstory = zeros(n,1);
for i=1:n
  idstory(i) = find(matches(com.story.floor_name, floor_name{i}));
end
idznominal = com.story.idnominal(idstory);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
subindex = cell(n,1);
for i=1:n
  subindex{i} = make_subindex(data{i,3});
end

% 断面リスト
section_list_name = cell(n,1);
full_name = cell(n,1);
id_section_list = zeros(n,1);
idmaterial = zeros(n,1);
for i=1:n
  full_name{i} = [subindex{i} name{i}];
  section_list_name{i} = tochar(data{i,4});
  idsl = find(strcmp(com.sectionList.name, section_list_name{i}), 1);
  if isempty(idsl)
    throw_err('IO', 'SectionListNotFound', section_list_name{i}, ...
      'S柱断面', ['符号: ' full_name{i}]);
  end
  id_section_list(i) = idsl;
end
type_name = com.sectionList.section_type_name(id_section_list);
list_type = com.sectionList.section_type(id_section_list);

% 鉄骨形状（第10列）。省略時は断面リストの鉄骨形状を継承する
shape_name = type_name;
if ncol >= 10
  for i=1:n
    shape = tochar(data{i,10});
    if ~isempty(shape)
      shape_name{i} = shape;
    end
  end
end
type = PRM.get_id_column_section_type(shape_name);
irow = find(isnan(type), 1);
if ~isempty(irow)
  throw_err('Input', 'ColumnShapeUnsupported', shape_name{irow}, ...
    floor_name{irow}, full_name{irow});
end

% 明示した形状は断面リストの鉄骨形状と整合させる。H／Iはともに
% H形鋼リストを利用する
irow = find(PRM.list_type_of_section_type(type) ~= list_type, 1);
if ~isempty(irow)
  throw_err('Input', 'ColumnShapeListMismatch', shape_name{irow}, ...
    section_list_name{irow}, floor_name{irow}, full_name{irow});
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
variable = cell(n,mvar);
idvar = zeros(n,mvar);
nvar = com.nvar;
nvrows = sum(~isnan(design_variable.isvar));
for i=1:n
  ndvar = PRM.nvar_of_section_type(type(i));
  cdata = data(i,5:(4+ndvar));
  variable(i,1:ndvar) = tochar(cdata);
  for j=1:ndvar
    idvar_ = find_design_variable_id(design_variable, variable{i,j});
    if isempty(idvar_)
      % 変数追加
      nvrows = nvrows+1;
      design_variable = ensure_design_variable_capacity( ...
        design_variable, nvrows);
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

% 部材種別（列9。空欄は既定値）
rank = options.coptions.rank_column * ones(n, 1);
if ncol >= 9
  for i = 1:n
    idx = find(strcmp(PRM.MEMBER_RANK_NAME, tochar(data{i,9})), 1);
    if ~isempty(idx)
      rank(i) = idx;
    end
  end
end

% 結果の保存
section_column = table(name, subindex, full_name, floor_name, ...
  id_section_list, type_name, idstory, type, idmaterial, idznominal, ...
  idvar, rank, dimension);

return
end
