function idnode = find_idnode_from_idxyz(idx, idy, idz, node)

% 通り番号から梁部材番号の検索
n = size(idx,1);
idnode = zeros(n,1);
iddn = 1:length(node.idx);
for i=1:n
  try
    idnode(i) = ...
      iddn(node.idx==idx(i) & node.idy==idy(i) & node.idz==idz(i));
  catch ME
  end
end

% 節点同一化により吸収された節点は代表節点に置換する。
% 吸収元節点は idx/idy/idz=0 に無効化済みで上記検索では見つからず、
% 未置換の呼び出し元では以降の処理で実行時エラーとなり顕在化する。
ispositive = idnode > 0;
idrep = zeros(n,1);
idrep(ispositive) = node.idrep(idnode(ispositive));
idnode(idrep>0) = idrep(idrep>0);
return
end

