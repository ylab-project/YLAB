function earthquake = extractEarthquakeForce(obj)
% データブロックの取り出し
data = obj.dataBlock.get_data_block('水平力・重心位置(一次)', 'X加力');
ndata = size(data,1);

% 計算の準備
story_name = cell(ndata,1);
floor_name = cell(ndata,1);
gx = zeros(ndata,1);
gy = zeros(ndata,1);
p = zeros(ndata,1);
ids = zeros(ndata,1);

% 地震力の読み出し
isss = 1:obj.nstory;
for i=1:ndata
  names = regexp(data{i,1}, '^([^(]+)(?:\(([^)]+)\))?', ...
    'tokens', 'once');
  story_name{i} = names{1};
  if numel(names) >= 2
    floor_name{i} = names{2};
  else
    floor_name{i} = story_name{i};
  end
  if ischar(data{i,2})
    data{i,2} = str2double(data{i,2}(1:end-1));
  end
  if ischar(data{i,3})
    data{i,3} = str2double(data{i,3}(1:end-1));
  end
  gx(i) = data{i,2};
  gy(i) = data{i,3};
  p(i) = data{i,4};

  % 層の検索
  ids(i) = isss(matches(obj.story.name, story_name{i}));
end

% 結果の整理
earthquake.story_name = story_name;
earthquake.floor_name = floor_name;
earthquake.idstory = ids;
earthquake.gx = gx;
earthquake.gy = gy;
earthquake.p = p;
end
