function xbaseline = set_xbaseline_block(dbc)
%set_xbaseline_block - X方向通り線データの読み込み

data = dbc.get_data_block('軸X');
n = size(data,1);
name = cell(n,1);
id = nan(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
  id(i) = data{i,2};
end

% 結果の保存
isdummy = false(n,1);
xbaseline = table(name, id, isdummy);
xbaseline = sortrows(xbaseline, 'id');
xbaseline.id = [];

return
end
