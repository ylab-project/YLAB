function [story, zbaseline] = set_story_block(dbc)
%set_story_block - 層データの読み込み

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
