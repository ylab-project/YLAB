function [floor, story] = set_floor_block(dbc, com)
%set_floor_block - 階データの読み込み

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
  story_name(i,:) = tochar(data(i,2:3));
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
floor = table(name, story_name, standard_height, height, ...
  diff_height, idstory, idz, isdummy, idnominal);
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
