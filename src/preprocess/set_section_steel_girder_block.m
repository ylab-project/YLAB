function [section_girder, design_variable] = ...
  set_section_steel_girder_block(dbc, com, options)
%set_section_steel_girder_block - S梁断面ブロックの読み込み
%
%   [section_girder, design_variable] = ...
%     set_section_steel_girder_block(dbc, com, options) は、入力データの
%   「S梁断面」ブロックを読み込み、S梁の断面情報テーブルと更新後の
%   設計変数構造体を返す。
%
%   入力引数:
%     dbc     - データブロックコンテナ
%     com     - 共通オブジェクト (story/baseline/sectionList 等)
%     options - 実行オプション (coptions.rank_girder 等)
%
%   出力引数:
%     section_girder  - S梁断面テーブル [n×15]
%       主要列: name, subindex, subindex_raw, story_name, full_name,
%       id_section_list, type_name, idstory, type, idmaterial, idz,
%       idznominal, idvar, rank, dimension
%     design_variable - 更新された設計変数構造体
%
%   備考:
%     - subindex は内部参照用（'-' は層番号に置換）、
%       subindex_raw は出力用の生値。
%     - 設計変数 idvar は (Hn,Bn,twn,tfn) 等の順で割り当てる。

data = dbc.get_data_block('S梁断面');
n = size(data,1);
design_variable = com.design.variable;

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
%   subindex     : 内部参照（full_name 構築）用。'-' は層番号に置換
%   subindex_raw : 出力用。入力時の生値を保持（'-' のまま）
subindex = cell(n,1);
subindex_raw = cell(n,1);
for i=1:n
  [subindex{i}, subindex_raw{i}] = make_subindex(data{i,3}, idstory(i));
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
  issl = strcmp(com.sectionList.name, section_list_name{i});
  if any(issl)
    idsl = iddd(issl);
    id_section_list(i) = idsl(1);
  else
    throw_err('IO', 'SectionListNotFound', ...
      section_list_name{i}, 'S梁断面', ...
      ['層: ' story_name{i} ', 符号: ' name{i}]);
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

% 寸法指定
dimension = zeros(n,mvar);

% 部材種別（列9固定）
rank = options.coptions.rank_girder*ones(n,1);
for i = 1:n
  if size(data, 2) >= 9 && ~all(ismissing(data{i, 9}))
    idx = find(strcmp(PRM.MEMBER_RANK_NAME, tochar(data{i, 9})), 1);
    if ~isempty(idx), rank(i) = idx; end
  end
end

% 結果の保存
section_girder = table(name, subindex, subindex_raw, story_name, ...
  full_name, id_section_list, type_name, idstory, type, idmaterial, ...
  idz, idznominal, idvar, rank, dimension);

return
end
