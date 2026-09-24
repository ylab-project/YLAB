function [idx, idy, idz, idir] = find_idxyz_node(...
  story_name, coord_name, baseline, frame_name)
n = size(story_name,1);

% 共通定数
nblx = size(baseline.x,1);

% 通り番号
idx = zeros(n,1);
idy = zeros(n,1);
idz = zeros(n,1);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = baseline.z.name;
for i=1:n
  idx(i) = find(matches(xlist, coord_name{i,1}));
  idy(i) = find(matches(ylist, coord_name{i,2}));
  idz(i) = find(matches(zlist, story_name{i}));
end

if nargin==3
  idir = [];
  return
end

% フレーム指定なし
idir = zeros(n,1);
if nargin==3
  return
end

% フレーム方向
xlist = baseline.x.name;
ylist = baseline.y.name;
xylist = [xlist(:)' ylist(:)'];
for i=1:n
  idxy = find(matches(xylist, frame_name{i}), 1);
  if idxy<=nblx
    idir(i) = PRM.Y;
  else
    idir(i) = PRM.X;
  end
end
return
end

