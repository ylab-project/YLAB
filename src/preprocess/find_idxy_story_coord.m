function [idx, idy, idz] = find_idxy_story_coord(...
  story_name, xcoord_name, ycoord_name, baseline, story)
n = size(story_name,1);

% 通り番号
m = size(xcoord_name,2);
idx = zeros(n,m); iddx = 1:size(baseline.x,1);
idy = zeros(n,m); iddy = 1:size(baseline.y,1);
idz = zeros(n,1); iddz = 1:size(baseline.z,1);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = story.name;
for i=1:n
  for j=1:m
    idx(i,j) = iddx(matches(xlist, xcoord_name{i,j}));
    idy(i,j) = iddy(matches(ylist, ycoord_name{i,j}));
    idz(i) = iddz(matches(zlist, story_name{i}));
  end
end

return
end

