function alignment_column = set_baseline_alignment_column_block(dbc, com)
%set_baseline_alignment_column_block - 柱の寄りデータの読み込み

data = dbc.get_data_block('柱の寄り');
n = size(data,1);

% データ読み取り
story_name = cell(n,1);
xcoord_name = cell(n,1);
ycoord_name = cell(n,1);
dx = zeros(n,1);
dy = zeros(n,1);
for i=1:n
  story_name{i} = tochar(data{i,1});
  xcoord_name{i} = tochar(data{i,2});
  ycoord_name{i} = tochar(data{i,3});
  val = data{i,4};
  if ~ismissing(val)
    dx(i) = val;
  end
  val = data{i,5};
  if ~ismissing(val)
    dy(i) = val;
  end
end

% 通り番号の検索
[idx, idy, idz] = find_idxy_floor_coord(story_name, ...
  xcoord_name, ycoord_name, com.baseline, com.floor);

% 結果の保存
column = table(idx, idy, idz, dx, dy);
alignment_column = column;

return
end
