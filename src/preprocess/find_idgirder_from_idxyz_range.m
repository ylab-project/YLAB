function idmeg = find_idgirder_from_idxyz_range(...
  idx, idy, idz, member_girder)
maxcol = 10;
n = size(idx,1);
idmeg = zeros(n,maxcol);

% 通り番号から梁部材番号の検索
idxlist = member_girder.idx;
idylist = member_girder.idy;
idzlist = member_girder.idz;
iddd = (1:size(member_girder,1))';
for i=1:n
  id = iddd(...
    (idx(i,1) <= idxlist(:,1)) & (idxlist(:,2) <= idx(i,2)) & ...
    (idy(i,1) <= idylist(:,1)) & (idylist(:,2) <= idy(i,2)) & ...
    (idz(i,1) <= idzlist(:,1)) & (idzlist(:,2) <= idz(i,2)));
  if ~isempty(id)
    idmeg(i,1:length(id)) = id;
  end
end

% 配列リサイズ
ncol = max(sum(idmeg>0,2));
idmeg = idmeg(:,1:ncol);

% 通り番号順に並び替え
% -> 必要か不明
for i=1:n
  ncol = nnz(idmeg(i,:));  
  if ncol<=1
    % 並び替えの必要なし
    continue
  end

  % X,Yの1方向だけの並び替え
  idx = idxlist(idmeg(i,1:ncol));
  idy = idylist(idmeg(i,1:ncol));
  if length(idx)>1
    [~, iddd] = sort(idx);
  else
    [~, iddd] = sort(idy);
  end
  idmeg(i,1:ncol) = idmeg(i,iddd);
end
return
end

