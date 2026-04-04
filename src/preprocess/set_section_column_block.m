function [section_column, design_variable] = ...
  set_section_column_block(dbc, com, options)
%set_section_column_block - S柱断面ブロックの読み込み

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
    throw_err('IO', 'SectionListNotFound', ...
      section_list_name{i}, 'S柱断面', ...
      ['符号: ' full_name{i}]);
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

% 部材種別（列9固定、梁と同様）
icol_rank = 9;
rank = options.coptions.rank_column * ones(n, 1);
for i = 1:n
  if size(data, 2) >= icol_rank ...
      && ~ismissing(data{i, icol_rank})
    idx = find(strcmp(PRM.MEMBER_RANK_NAME, ...
      tochar(data{i, icol_rank})), 1);
    if ~isempty(idx), rank(i) = idx; end
  end
end

% 結果の保存
section_column = table(name, subindex, full_name, ...
  floor_name, id_section_list, type_name, idstory, ...
  type, idmaterial, idznominal, idvar, rank, dimension);

return
end
