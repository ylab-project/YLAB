function [idx, idy, idz] = find_idxy_floor_coord(...
  floor_name, xcoord_name, ycoord_name, baseline, floor)
n = size(floor_name,1);

% 通り番号
m = size(floor_name,2);
idx = zeros(n,m);
idy = zeros(n,m);
idz = zeros(n,m);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = floor.name;
for i=1:n
  for j=1:m
    idx(i,j) = find(matches(xlist, xcoord_name{i,j}));
    idy(i,j) = find(matches(ylist, ycoord_name{i,j}));
    idz(i,j) = floor.idz(matches(zlist, floor_name{i,j}));
  end
end

return
end

