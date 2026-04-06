function [section_girder, design_variable] = ...
  set_section_steel_girder_block(dbc, com, options)
%set_section_steel_girder_block - S梁断面ブロックの読み込み
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

% 部材種別（列9固定）
rank = options.coptions.rank_girder*ones(n,1);
for i = 1:n
  if size(data, 2) >= 9 && ~all(ismissing(data{i, 9}))
    idx = find(strcmp(PRM.MEMBER_RANK_NAME, ...
      tochar(data{i, 9})), 1);
    if ~isempty(idx), rank(i) = idx; end
  end
end

% 結果の保存
section_girder = table(name, subindex, story_name, full_name, ...
  id_section_list, type_name, idstory, type, idmaterial, ...
  idz, idznominal, idvar, rank, dimension);

return
end
