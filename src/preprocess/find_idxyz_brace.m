function [idx, idy, idz, idir, idznominal] = find_idxyz_brace(...
  floor_name, frame_name, coord_name, baseline, story)

% 定数
n = size(frame_name,1);
m = size(floor_name,2);

% 共通定数
nblx = size(baseline.x,1);
nbly = size(baseline.y,1);
nblz = size(baseline.z,1);

% 通り番号
idir = zeros(n,1);
idx = zeros(n,2); iddx = 1:nblx;
idy = zeros(n,2); iddy = 1:nbly;
idz = zeros(n,2); iddz = 1:nblz;
iddd = 1:(nblx+nbly);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = story.floor_name;
xylist = [xlist(:)' ylist(:)'];
for i=1:n
  idxy = iddd(matches(xylist, frame_name{i}));
  if isempty(idxy)
    continue
  end
  if idxy<=nblx
    idir(i) = PRM.Y;
    idx(i,:) = idxy;
    idy(i,1) = iddy(matches(ylist, coord_name{i,1}));
    idy(i,2) = iddy(matches(ylist, coord_name{i,2}));
  else
    idir(i) = PRM.X;
    idy(i,:) = idxy-nblx;
    idx(i,1) = iddx(matches(xlist, coord_name{i,1}));
    idx(i,2) = iddx(matches(xlist, coord_name{i,2}));
  end
  % idz(i,:) = iddz(matches(baseline.z.name, story_name{i}));
  idz(i,1) = iddz(matches(zlist, floor_name{i,1}))-1;
  idz(:,2) = idz(:,1)+1;
end

% ID変換：ダミー層->名目層
if nargout==5
  idznominal = baseline.z.idnominal(idz);
  if size(idznominal,1)~=n
    idznominal = idznominal';
  end
end
return
end

