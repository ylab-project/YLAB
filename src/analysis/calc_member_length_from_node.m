function lm = calc_member_length_from_node(node, idm2n)
%calc_member_length_from_node - 節点座標から部材長を計算

lm = sqrt((node.x(idm2n(:, 2)) - node.x(idm2n(:, 1))).^2 ...
  + (node.y(idm2n(:, 2)) - node.y(idm2n(:, 1))).^2 ...
  + (node.z(idm2n(:, 2)) - node.z(idm2n(:, 1))).^2);

return
end