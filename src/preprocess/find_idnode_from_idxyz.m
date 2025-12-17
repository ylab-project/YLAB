function idnode = find_idnode_from_idxyz(idx, idy, idz, node)

% 通り番号から梁部材番号の検索
n = size(idx,1);
idnode = zeros(n,1);
iddn = 1:size(node,1);
for i=1:n
  try
    idnode(i) = ...
      iddn(node.idx==idx(i) & node.idy==idy(i) & node.idz==idz(i));
  catch ME
  end
end

% idrep = node.idrep(idnode);
% idnode(idrep>0) = idrep(idrep>0);
return
end

