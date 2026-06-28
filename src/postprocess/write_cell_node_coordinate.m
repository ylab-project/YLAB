function [head, body] = write_cell_node_coordinate(result)
%write_cell_node_coordinate - 節点座標(構造心)のセル配列を生成

node = result.node;
baseline = result.baseline;

head = {'層', 'X軸', 'Y軸', '座標', '', '', '回転'; ...
  '', '', '', 'X', 'Y', 'Z', ''; ...
  '', '', '', 'mm', 'mm', 'mm', '度'};

nn = length(node.x);
body = cell(nn, 7);
irow = 0;

is_output = node.type == PRM.NODE_STANDARD ...
  | node.type == PRM.NODE_FLEX_DIAPHRAGM;
for iz = height(baseline.z):-1:1
  in_story = find(node.idz == iz & is_output & node.idrep == 0);
  if isempty(in_story)
    continue
  end
  [~, isort] = sortrows([node.idy(in_story), node.idx(in_story)]);
  in_story = in_story(isort);
  for i = 1:length(in_story)
    in = in_story(i);
    irow = irow + 1;
    body{irow, 1} = node.zname{in};
    body{irow, 2} = node.xname{in};
    body{irow, 3} = node.yname{in};
    body{irow, 4} = sprintf('%.0f', node.x(in));
    body{irow, 5} = sprintf('%.0f', node.y(in));
    body{irow, 6} = sprintf('%.0f', node.z(in));
    body{irow, 7} = '0.00';
  end
end

body = body(1:irow, :);

return
end