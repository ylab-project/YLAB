function baseline_setback = set_baseline_setback_block(dbc, com)
%set_baseline_setback_block - セットバックデータの読み込み

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
baseline_setback = table(story_name, xname, ...
  yname, dx, dy, idstory, idx, idy);

return
end
