function [ng_node1, ng_node2] = ...
  get_nominal_girder_end_nodes(girder, idmeg)
%get_nominal_girder_end_nodes - 名目梁の端部節点を取得
%   i端=最初の部材のi端、j端=最後の部材のj端。

nng = size(idmeg, 1);
ng_node1 = girder.idnode1(idmeg(:, 1));
ng_node2 = zeros(nng, 1);
for ing = 1:nng
  ids = nonzeros(idmeg(ing, :));
  ng_node2(ing) = girder.idnode2(ids(end));
end

return
end
