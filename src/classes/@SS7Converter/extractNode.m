function node = extractNode(obj)
% データブロックの取り出し
data = obj.dataBlock.get_data_block('節点座標(構造心)');
n = size(data,1);

% 通り・層名
xname = cell(n,1);
yname = cell(n,1);
story_name = cell(n,1);
for i=1:n
  xname{i} = tochar(data{i,2});
  yname{i} = tochar(data{i,3});
  story_name{i} = tochar(data{i,1});
end

% 通り・層番号
idx = zeros(n,1); iddx = 1:obj.nblx;
idy = zeros(n,1); iddy = 1:obj.nbly;
idstory = zeros(n,1); idds = 1:obj.nstory;
for i=1:n
  idx(i) = iddx(matches(obj.baseline.x.name, xname{i}));
  idy(i) = iddy(matches(obj.baseline.y.name, yname{i}));
  idstory(i) = idds(matches(obj.story.name, story_name{i}));
end

% 座標値
x = cell2mat(data(:,4));
y = cell2mat(data(:,5));
z = cell2mat(data(:,6));

% テーブルの作成
node = table(xname, yname, story_name, x, y, z, idx, idy, idstory);
end
