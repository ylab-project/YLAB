function yspan = set_yspan_block(dbc, com)
%set_yspan_block - Y方向スパンデータの読み込み

data = dbc.get_data_block('スパンY方向');
n = size(data,1);
name = cell(n,1);
standard_span = zeros(n,1);
span = zeros(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
  standard_span(i) = data{i,2};
  span(i) = data{i,3};
end

% 通り番号
idy = zeros(n,1); iddy = 1:com.nbly;
for i=1:n
  idy(i) = iddy(matches(com.baseline.y.name, name{i}));
end
yspan = table(name, standard_span, span, idy);

return
end
