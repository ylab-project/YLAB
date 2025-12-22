function [node, isdummy_node] = set_node_block(dbc, com)
%set_node_block - 節点ブロックの読み込みと節点テーブルの作成

% 計算の準備
baseline = com.baseline;
story = com.story;
nblx = size(baseline.x,1);
nbly = size(baseline.y,1);
nblz = size(baseline.z,1);
isused_girder = false(nblx, nbly, nblz);
isused_column = false(nblx, nbly, nblz);
isdummy_node = false(nblx, nbly, nblz);

%% 梁で指定された節点の検索
data_girder = dbc.get_data_block('大梁配置');
ng = size(data_girder,1);

% 層名・通り名
story_name = cell(ng,1);
frame_name = cell(ng,1);
coord_name = cell(ng,2);
for i=1:ng
  story_name{i} = tochar(data_girder{i,1});
  frame_name{i} = tochar(data_girder{i,2});
  coord_name(i,:) = tochar(data_girder(i,3:4));
end

% 通り番号・方向
[idx, idy, idz] = find_idxyz_girder(...
  story_name, frame_name, coord_name, baseline);
for i=1:ng
  for j=1:2
    isused_girder(idx(i,j),idy(i,j),idz(i,j)) = true;
  end
end

%% 柱で指定された節点の検索
data_column = dbc.get_data_block('柱配置');
nc = size(data_column,1);

% 階名・通り名
floor_name = cell(nc,2);
xcoord_name = cell(nc,2);
ycoord_name = cell(nc,2);
for i=1:nc
  floor_name{i,1} = tochar(data_column{i,1});
  floor_name{i,2} = tochar(data_column{i,1});
  if ~ismissing(data_column{i,7})
    floor_name{i,2} = tochar(data_column{i,7});
  end
  xcoord_name{i,1} = tochar(data_column(i,2));
  xcoord_name{i,2} = tochar(data_column(i,2));
  ycoord_name{i,1} = tochar(data_column(i,3));
  ycoord_name{i,2} = tochar(data_column(i,3));
end

% 通り番号・方向
[idx, idy, idz] = find_idxyz_column(...
  floor_name, xcoord_name, ycoord_name, baseline, story);
for i=1:nc
  for j=1:2
    isused_column(idx(i,j),idy(i,j),idz(i,j)) = true;
  end
end

% 梁か柱で使われている
isused = isused_girder|isused_column;

%% 節点ブロックからダミー指定を読み込み（保持対象の節点）
iskeep_node = false(nblx, nbly, nblz);
data = dbc.get_data_block('節点');
n = size(data,1);
if n > 0
  story_name_ = cell(n,1);
  coord_name_ = cell(n,2);
  for i=1:n
    story_name_{i} = tochar(data{i,1});
    coord_name_(i,:) = tochar(data(i,2:3));
  end
  [idx_, idy_, idz_] = find_idxyz_node(story_name_, coord_name_, baseline);
  for i=1:n
    % 列8にダミー指定（T）がある場合は保持
    flag = tochar(data{i,8});
    if ~ismissing(flag)
      if matches(flag, 'T')
        iskeep_node(idx_(i), idy_(i), idz_(i)) = true;
      end
    end
  end
end
% ダミー指定された節点はisusedにも追加
isused = isused | iskeep_node;

%% ダミー層で柱梁がとりつかない節点は削除（ダミー指定された節点は保持）
isdummy_node(:,:,story.isdummy) = true;
isdummy_node = isdummy_node & ~isused_girder & ~iskeep_node;
isused = isused & ~isdummy_node;

%% 節点
nnode = sum(reshape(isused,[],1));
xname = cell(nnode,1);
yname = cell(nnode,1);
zname = cell(nnode,1);
idnode = zeros(nblx, nbly, nblz);
idx = zeros(nnode,1);
idy = zeros(nnode,1);
idz = zeros(nnode,1);
idstory = zeros(nnode,1);
idz2story = 1:nblz; idz2story = idz2story(story.idz);
xyz = zeros(nnode,3);
dz = zeros(nnode,1);
xcoord = com.baseline.x.coord;
ycoord = com.baseline.y.coord;
zcoord = com.baseline.z.coord;

% 節点情報の数え上げ
id = 0;
for k=1:nblz
  for j=1:nbly
    for i=1:nblx
      if isused(i,j,k)
        id = id+1;
        idnode(i,j,k) = id;
        xname(id) = baseline.x.name(i);
        yname(id) = baseline.y.name(j);
        zname(id) = baseline.z.name(k);
        idx(id) = i;
        idy(id) = j;
        idz(id) = k;
        idstory(id) = idz2story(k);
        xyz(id,:) = [xcoord(i) ycoord(j) zcoord(k)];
      end
    end
  end
end

%% 節点移動
% data = dbc.get_data_block('節点');
% n = size(data,1);

% 通り・層名
% 層名・通り名
story_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,1});
  coord_name(i,:) = tochar(data(i,2:3));
end
[idx_, idy_, idz_] = find_idxyz_node(story_name, coord_name, baseline);
idn_ = zeros(n,1);
for i=1:n
  idn_(i) = idnode(idx_(i), idy_(i), idz_(i));
end

% TODO: 要修正
for i=1:n
  xyzval = [data{i,4} data{i,5} data{i,6}];
  if all(ismissing(xyzval))
    continue
  end
  flag = tochar(data{i,7});
  if all(~ismissing(xyzval)) && ~ismissing(flag)
    isrel = ~matches(flag,'F');
  else
    isrel = true;
  end
  for j=1:3
    if ~ismissing(xyzval(j))
      id = idn_(i);
      if id<=0, continue; end
      % 移動量
      if j==3
        % Z座標
        if isrel
          dz(id) = xyzval(j);
        else
          dz(id) = xyzval(j)-xyz(i,j);
        end
      else
        % XY座標
        if isrel
          xyz(id,j) = xyz(id,j) + xyzval(j);
        else
          xyz(id,j) = xyzval(j);
        end
      end
    end
  end
end
x = xyz(:,1);
y = xyz(:,2);
z = xyz(:,3);

% 節点種別
type = ones(nnode,1)*PRM.NODE_STANDARD;

% 代表節点
idrep = zeros(nnode,1);

% 結果の保存
node = table(xname, yname, zname, x, y, z, dz, idx, idy, idz, ...
  type, idstory, idrep);

return
end
