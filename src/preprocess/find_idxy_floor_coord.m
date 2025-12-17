function [idx, idy, idz] = find_idxy_floor_coord(...
  floor_name, xcoord_name, ycoord_name, baseline, floor)
n = size(floor_name,1);

% 通り番号
m = size(floor_name,2);
idx = zeros(n,m); iddx = 1:size(baseline.x,1);
idy = zeros(n,m); iddy = 1:size(baseline.y,1);
idz = zeros(n,m); iddz = floor.idz;
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = floor.name;
for i=1:n
  for j=1:m
    idx(i,j) = iddx(matches(xlist, xcoord_name{i,j}));
    idy(i,j) = iddy(matches(ylist, ycoord_name{i,j}));
    idz(i,j) = iddz(matches(zlist, floor_name{i,j}));
  end
end

return
end

