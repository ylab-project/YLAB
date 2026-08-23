function idnode = find_idnode_from_grid(com, ix, iy, istory)
%find_idnode_from_grid - グリッドと層から帳票対象の節点番号を返す
%
%   idnode = find_idnode_from_grid(com, ix, iy, istory) は、指定した
%   X軸・Y軸グリッドと層に属する帳票対象の節点番号を返す。ブレース用
%   の柱分割節点と、同一化で代表節点を持つ節点は除く。節点重量表と
%   地震時節点重量表の行構成、および分析層の累計はこの対象定義を
%   共有する。
%
%   入力引数:
%     com    - 節点情報
%     ix,iy  - X・Yグリッド番号
%     istory - 層番号
%
%   出力引数:
%     idnode - 帳票対象の節点番号
node = com.node;
idnode = find(node.idx == ix & node.idy == iy & node.idstory == istory);
idnode = idnode(node.type(idnode) ~= PRM.NODE_BRACE_FOR_COLUMN ...
  & node.idrep(idnode) == 0);

return
end
