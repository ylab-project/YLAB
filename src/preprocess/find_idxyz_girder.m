function [idx, idy, idz, idir, idznominal] = find_idxyz_girder(...
  story_name, frame_name, coord_name, baseline)

% 定数
n = size(frame_name,1);
m = size(frame_name,2);

% 共通定数
nblx = size(baseline.x,1);
nbly = size(baseline.y,1);
nblz = size(baseline.z,1);

% 通り番号
idir = zeros(n,1);
idx = zeros(n,2); iddx = 1:size(baseline.x,1);
idy = zeros(n,2); iddy = 1:size(baseline.y,1);
idz = zeros(n,2); iddz = 1:size(baseline.z,1);
iddd = 1:(nblx+nbly);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = baseline.z.name;
xylist = [xlist(:)' ylist(:)'];
if m==1
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
    idz(i,:) = iddz(matches(zlist, story_name{i}));
  end
else
  for i=1:n
    idxy = iddd(matches(xylist, frame_name{i,1}));
    if isempty(idxy)
      continue
    end
    if idxy<=nblx
      idir(i) = PRM.Y;
      idx(i,1) = iddd(matches(xlist, frame_name{i,1}));
      idx(i,2) = iddd(matches(xlist, frame_name{i,2}));
      idy(i,1) = iddy(matches(ylist, coord_name{i,1}));
      idy(i,2) = iddy(matches(ylist, coord_name{i,2}));
    else
      idir(i) = PRM.X;
      idy(i,1) = iddd(matches(ylist, frame_name{i,1}));
      idy(i,2) = iddd(matches(ylist, frame_name{i,2}));
      idx(i,1) = iddx(matches(xlist, coord_name{i,1}));
      idx(i,2) = iddx(matches(xlist, coord_name{i,2}));
    end
    idz(i,1) = iddz(matches(zlist, story_name{i,1}));
    idz(i,2) = iddz(matches(zlist, story_name{i,2}));
  end
end

% ID変換：ダミー層->名目層
if nargout==5
  idznominal = baseline.z.idnominal(idz);
end
return
end

