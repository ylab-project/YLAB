function [idx, idy, idz] = find_idxyz_column(...
  floor_name, xcoord_name, ycoord_name, baseline, story)

% 共通定数
n = size(floor_name,1);
m = size(floor_name,2);

% 通り番号
idx = zeros(n,2); iddx = 1:size(baseline.x,1);
idy = zeros(n,2); iddy = 1:size(baseline.y,1);
idz = zeros(n,2); iddz = 1:size(baseline.z,1);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = story.floor_name;
if m==1
  for i=1:n
    idx(i,1) = iddx(matches(xlist, xcoord_name{i,1}));
    idy(i,1) = iddy(matches(ylist, ycoord_name{i,1}));
    idz(i,1) = iddz(matches(zlist, floor_name{i,1}))-1;
  end
  idx(:,2) = idx(:,1);
  idy(:,2) = idy(:,1);
  idz(:,2) = idz(:,1)+1;
else
  for i=1:n
    idx(i,1) = iddx(matches(xlist, xcoord_name{i,1}));
    idx(i,2) = iddx(matches(xlist, xcoord_name{i,2}));
    idy(i,1) = iddy(matches(ylist, ycoord_name{i,1}));
    idy(i,2) = iddy(matches(ylist, ycoord_name{i,2}));
    idz(i,1) = iddz(matches(zlist, floor_name{i,1}))-1;
    idz(i,2) = iddz(matches(zlist, floor_name{i,2}));
  end
end
return
end

