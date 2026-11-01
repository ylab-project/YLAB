function fnode = parse_legacy_nodal_force_block(nodal_force, com)
%parse_legacy_nodal_force_block - 従来節点荷重を作用節点へ加算する
%
%   fnode = parse_legacy_nodal_force_block(nodal_force, com) は、
%   正規化済みの配置指定から節点を検索し、ケース別荷重を加算する。
%
%   入力引数:
%     nodal_force - 配置指定・ケース・6成分・入力位置のテーブル
%     com         - 節点と基準線、荷重ケースを持つ解析モデル
%
%   出力引数:
%     fnode - 荷重ケース別の節点荷重 [nnode×6×nlc]

fnode = zeros(com.nnode, 6, com.nlc);
for ir = 1:height(nodal_force)
  names = nodal_force.selector(ir, :);
  idnode = find_idnode_from_names(names{1}, names{2}, names{3}, com);
  if idnode == 0
    throw_err('Input', 'NodeNotFound', nodal_force.irow(ir));
  end
  ilc = nodal_force.ilc(ir);
  fnode(idnode, :, ilc) = fnode(idnode, :, ilc) + nodal_force.f(ir, :);
end

return
end
