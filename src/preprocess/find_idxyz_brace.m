function [idx, idy, idz, idir] = find_idxyz_brace(floor_name, ...
  frame_name, coord_name, baseline, story)

% 定数
n = size(frame_name,1);

% 共通定数
nblx = size(baseline.x,1);

% 通り番号
idir = zeros(n,1);
idx = zeros(n,2);
idy = zeros(n,2);
idz = zeros(n,2);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = story.floor_name;
xylist = [xlist(:)' ylist(:)'];
for i=1:n
  idxy = find(matches(xylist, frame_name{i}), 1);
  if isempty(idxy)
    continue
  end
  if idxy<=nblx
    idir(i) = PRM.Y;
    idx(i,:) = idxy;
    idy(i,1) = find(matches(ylist, coord_name{i,1}));
    idy(i,2) = find(matches(ylist, coord_name{i,2}));
  else
    idir(i) = PRM.X;
    idy(i,:) = idxy-nblx;
    idx(i,1) = find(matches(xlist, coord_name{i,1}));
    idx(i,2) = find(matches(xlist, coord_name{i,2}));
  end
  idz(i,1) = find(matches(zlist, floor_name{i,1}))-1;
  idz(:,2) = idz(:,1)+1;
end
return
end

