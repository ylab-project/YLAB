function baseline_delta = set_baseline_delta_block(dbc, com)
%set_baseline_delta_block - 軸振れデータの読み込み

data = dbc.get_data_block('軸振れ');
n = size(data,1);

% 共通定数
nblx = com.nblx;
nbly = com.nbly;

% データ読み取り
xname = cell(n,1);
yname = cell(n,1);
dx = zeros(n,1);
dy = zeros(n,1);
for i=1:n
  xname{i} = tochar(data{i,1});
  yname{i} = tochar(data{i,2});
  dx(i) = data{i,3};
  dy(i) = data{i,4};
end

% 通り番号の検索
idx = zeros(n,1);
idy = zeros(n,1);
iddd = 1:max([nblx nbly]);
for i=1:n
  % X通り
  id = matches(com.baseline.x.name, xname{i});
  if any(id)
    idx(i) = iddd(id);
  end

  % Y通り
  id = matches(com.baseline.y.name, yname{i});
  if any(id)
    idy(i) = iddd(id);
  end
end

% 結果の保存
baseline_delta = table(xname, yname, dx, dy, idx, idy);

return
end
