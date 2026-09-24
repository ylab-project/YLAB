function [idx, idy, idz] = find_idxy_story_coord(...
  story_name, xcoord_name, ycoord_name, baseline, story)
n = size(story_name,1);

% 通り番号
m = size(xcoord_name,2);
idx = zeros(n,m);
idy = zeros(n,m);
idz = zeros(n,1);
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = story.name;
for i=1:n
  for j=1:m
    idx(i,j) = find(matches(xlist, xcoord_name{i,j}));
    idy(i,j) = find(matches(ylist, ycoord_name{i,j}));
    idz(i) = find(matches(zlist, story_name{i}));
  end
end

return
end

