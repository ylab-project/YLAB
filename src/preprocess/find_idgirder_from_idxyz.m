function idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder, idir)
n = size(idx,1);
idmeg = zeros(n,100);

% 向きを考慮するか
if nargin==4
  MODE_DIR=false;
else
  MODE_DIR=true;
end

% 通り番号から梁部材番号の検索
idxlist = member_girder.idx;
idylist = member_girder.idy;
idzlist = member_girder.idz;
idirlist = member_girder.idir;
iddd = (1:size(member_girder,1))';
ncol = 1;
for i=1:n
  if MODE_DIR
    id = iddd(...
      (idx(i,1) <= idxlist(:,1)) & (idxlist(:,2) <= idx(i,2)) & ...
      (idy(i,1) <= idylist(:,1)) & (idylist(:,2) <= idy(i,2)) & ...
      (idz(i,1) <= idzlist(:,1)) & (idzlist(:,2) <= idz(i,2)) & ...
      idir(i) == idirlist);
  else
    id = iddd(...
      (idx(i,1) <= idxlist(:,1)) & (idxlist(:,2) <= idx(i,2)) & ...
      (idy(i,1) <= idylist(:,1)) & (idylist(:,2) <= idy(i,2)) & ...
      (idz(i,1) <= idzlist(:,1)) & (idzlist(:,2) <= idz(i,2)));
  end
  if ~isempty(id)
    ncol = max(ncol,length(id));
    idmeg(i,1:length(id)) = id;
  end
end
idmeg = idmeg(:,1:ncol);
return
end

