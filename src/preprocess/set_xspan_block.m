function xspan = set_xspan_block(dbc, com)
%set_xspan_block - X方向スパンデータの読み込み

data = dbc.get_data_block('スパンX方向');
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
idx = zeros(n,1); iddx = 1:com.nblx;
for i=1:n
  idx(i) = iddx(matches(com.baseline.x.name, name{i}));
end
xspan = table(name, standard_span, span, idx);

return
end
