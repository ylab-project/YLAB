function alignment = set_baseline_alignment_block(dbc, com)
%set_baseline_alignment_block - 部材の寄りデータの読み込み

data = dbc.get_data_block('部材の寄り');
n = size(data,1);

% 共通定数
nblx = com.nblx;
nbly = com.nbly;

% データ読み取り
xy_frame_name = cell(n,1);
alignment_column = zeros(n,1);
alignment_girder = zeros(n,1);
for i=1:n
  xy_frame_name{i} = tochar(data{i,1});
  alignment_column(i) = data{i,2};
  alignment_girder(i) = data{i,3};
end

% 通り番号の検索
idir = zeros(n,1);
idxy = zeros(n,1); iddd = 1:max([nblx nbly]);
for i=1:n
  % X通り
  idx = matches(com.baseline.x.name, xy_frame_name{i});
  if any(idx)
    idir(i) = PRM.X;
    idxy(i) = iddd(idx);
    continue
  end

  % Y通り
  idy = matches(com.baseline.y.name, xy_frame_name{i});
  if any(idy)
    idir(i) = PRM.Y;
    idxy(i) = iddd(idy);
  end
end

% X方向
idx = idxy(idir==PRM.X);
frame_name = com.baseline.x.name;
column = zeros(nblx,1);
girder = zeros(nblx,1);
column(idx) = alignment_column(idir==PRM.X);
girder(idx) = alignment_girder(idir==PRM.X);
x = table(frame_name, column, girder);

% Y方向
idy = idxy(idir==PRM.Y);
frame_name = com.baseline.y.name;
column = zeros(nbly,1);
girder = zeros(nbly,1);
column(idy) = alignment_column(idir==PRM.Y);
girder(idy) = alignment_girder(idir==PRM.Y);
y = table(frame_name, column, girder);

% 結果の保存
alignment.x = x;
alignment.y = y;

return
end
