function node = update_brace_column_node_z(...
  node, zcoord_standard, member_girder)
%update_brace_column_node_z - 基礎梁天端追加節点のZ座標を更新

if istable(node)
  has_idfg = ismember('idfg_brace_top', node.Properties.VariableNames);
  has_idz = ismember('idz_brace_top', node.Properties.VariableNames);
else
  has_idfg = isfield(node, 'idfg_brace_top');
  has_idz = isfield(node, 'idz_brace_top');
end
if ~has_idfg || ~has_idz
  return
end

is_target = node.type == PRM.NODE_BRACE_FOR_COLUMN;
if ~any(is_target)
  return
end

idfg = node.idfg_brace_top(is_target);
idz = node.idz_brace_top(is_target);
if any(idfg <= 0) || any(idz <= 0)
  error('update_brace_column_node_z:InvalidBraceTopNode', ...
    '基礎梁天端追加節点の対象基礎梁または対象階が未設定です。');
end

node.z_standard(is_target) = zcoord_standard(idz) + node.dz(is_target);
node.z(is_target) = zcoord_standard(idz) + node.dz(is_target) ...
  + member_girder.level(idfg);

return
end