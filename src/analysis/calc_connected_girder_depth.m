function depth = calc_connected_girder_depth( ...
  node_id, girder_node, girder_depth, is_target)
%calc_connected_girder_depth - 節点に接続する梁せいの最大値を取得
%
%   depth = calc_connected_girder_depth(node_id, girder_node,
%   girder_depth, is_target) は、指定節点に接続する対象梁のうち
%   最大の梁せいを返す。対象梁がなければ 0 を返す。
%
%   入力引数:
%     node_id      - 対象節点番号
%     girder_node  - 梁端節点番号 [nmg×2]
%     girder_depth - 梁せい [nmg×1]
%     is_target    - 対象梁フラグ [nmg×1]
%
%   出力引数:
%     depth - 接続梁せいの最大値

if nargin < 4 || isempty(is_target)
  is_target = true(size(girder_depth));
end

is_target = is_target(:);
girder_depth = girder_depth(:);
is_connected = girder_node(:, 1) == node_id ...
  | girder_node(:, 2) == node_id;
idx = is_connected & is_target & girder_depth > 0;

if any(idx)
  depth = max(girder_depth(idx));
else
  depth = 0;
end

return
end
