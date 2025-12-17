function [idx, idy, idz, idir] = find_idxyz_node(...
  story_name, coord_name, baseline, frame_name)
n = size(story_name,1);

% 共通定数
nblx = size(baseline.x,1);
nbly = size(baseline.y,1);
% nblz = size(baseline.z,1);

% 通り番号
idx = zeros(n,1); iddx = 1:size(baseline.x,1);
idy = zeros(n,1); iddy = 1:size(baseline.y,1);
idz = zeros(n,1); iddz = 1:size(baseline.z,1);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = baseline.z.name;
for i=1:n
  idx(i) = iddx(matches(xlist, coord_name{i,1}));
  idy(i) = iddy(matches(ylist, coord_name{i,2}));
  idz(i) = iddz(matches(zlist, story_name{i}));
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
iddd = 1:(nblx+nbly);
for i=1:n
  idxy = iddd(matches(xylist, frame_name{i}));
  if idxy<=nblx
    idir(i) = PRM.Y;
  else
    idir(i) = PRM.X;
  end
end
return
end

