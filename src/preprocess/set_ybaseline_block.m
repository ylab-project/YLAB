function ybaseline = set_ybaseline_block(dbc)
%set_ybaseline_block - Y方向通り線データの読み込み

data = dbc.get_data_block('軸Y');
n = size(data,1);
name = cell(n,1);
id = nan(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
  id(i) = data{i,2};
end

% 結果の保存
isdummy = false(n,1);
ybaseline = table(name, id, isdummy);
ybaseline = sortrows(ybaseline, 'id');
ybaseline.id = [];

return
end
