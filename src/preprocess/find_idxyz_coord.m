function [idx, idy, idz] = find_idxyz_coord(...
  story_name, xcoord_name, ycoord_name, baseline)
n = size(story_name,1);

% 共通定数
nblx = size(baseline.x,1);
nbly = size(baseline.y,1);
nblz = size(baseline.z,1);

% 通り番号
m = size(story_name,2);
idx = zeros(n,m); iddx = 1:nblx;
idy = zeros(n,m); iddy = 1:nbly;
idz = zeros(n,m); iddz = 1:nblz;
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = baseline.z.name;
for i=1:n
  for j=1:m
    idx(i,j) = iddx(matches(xlist, xcoord_name{i,j}));
    idy(i,j) = iddy(matches(ylist, ycoord_name{i,j}));
    idz(i,j) = iddz(matches(zlist, story_name{i,j}));
  end
end

return
end

