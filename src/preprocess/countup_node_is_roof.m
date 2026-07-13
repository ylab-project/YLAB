function is_roof = countup_node_is_roof(com)
%countup_node_is_roof - 梁配置から屋根面相当節点を判定する
%
%   is_roof = countup_node_is_roof(com) は、節点ごとに上方の
%   梁構面の有無を調べ、屋根面相当かどうかを方向別配列で返す。
%
%   入力引数:
%     com - 共通オブジェクト（node, member.girder を含む）
%
%   出力引数:
%     is_roof - 屋根面相当フラグ [nnode x 2]。1列目がX方向、
%       2列目がY方向。

% 共通配列
node = com.node;
girder = com.member.girder;
nnode = com.nnode;

node_x = node.idx;
node_y = node.idy;
node_z = node.idz;

girder_x1 = min(girder.idx, [], 2);
girder_x2 = max(girder.idx, [], 2);
girder_y1 = min(girder.idy, [], 2);
girder_y2 = max(girder.idy, [], 2);
girder_z = min(girder.idz, [], 2);

is_roof = true(nnode, 2);
for inode = 1:nnode
  is_upper = girder_z > node_z(inode);
  covers_x = girder_x1 <= node_x(inode) & node_x(inode) <= girder_x2;
  covers_y = girder_y1 <= node_y(inode) & node_y(inode) <= girder_y2;

  has_upper_girder = any(is_upper & covers_x & covers_y);

  is_roof(inode, :) = ~has_upper_girder;
end
return
end
