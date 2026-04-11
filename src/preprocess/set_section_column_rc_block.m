function section_column = set_section_column_rc_block(dbc, com)
%set_section_column_rc_block - RC柱断面データの読み込み

data = dbc.get_data_block('RC柱断面');
if isempty(data)
  % RC柱断面がない場合は空のテーブルを返す
  section_column = table();
  return;
end

n = size(data,1);

% 階名
floor_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
end

% 層番号（S柱断面と同じ方法）
idstory = zeros(n,1);
iddd = 1:com.nstory;
for i=1:n
  idx = strcmp(com.story.floor_name, floor_name{i});
  if any(idx)
    idstory(i) = iddd(idx);
  else
    error('階 %s が見つかりません (RC柱断面)', floor_name{i});
  end
end
idznominal = com.baseline.z.idnominal(idstory);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
subindex = cell(n,1);
for i=1:n
  subindex{i} = data{i,3};
  if isnumeric(subindex{i})
    subindex{i} = num2str(subindex{i});
  elseif subindex{i} =='-'
    subindex{i} ='';
  end
end

% 断面リスト
full_name = cell(n,1);
idmaterial = zeros(n,1);
id_section_list = zeros(n,1);  % 最適化対象外
type = zeros(n,1);
type_name = cell(n,1);
iddd = 1:com.nma;
for i=1:n
  full_name{i} = [subindex{i} name{i}];
  idmaterial(i) = iddd(matches(com.material.name, data{i,7}));
  type(i) = PRM.RCRS;  % RC矩形断面
  type_name{i} = 'RCRS';
end

% 設計変数番号（最適化対象外のため0）
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);

% 寸法指定
dimension = zeros(n,mvar);
for i=1:n
  % Dx×Dy（形状は□なので正方形または矩形）
  dimension(i,1:2) = [data{i,5} data{i,6}];
  % 荷重剛性用Dx×Dy
  dimension(i,3:4) = dimension(i,1:2);
  if isnumeric(data{i,8}) && ~ismissing(data{i,8}) && data{i,8}>0
    dimension(i,3) = data{i,8};
  end
  if isnumeric(data{i,9}) && ~ismissing(data{i,9}) && data{i,9}>0
    dimension(i,4) = data{i,9};
  end
end

% 部材種別（RC柱はランク対象外）
rank = PRM.RANK_NONE * ones(n, 1);

% 結果の保存（S柱断面と同じテーブル構造）
section_column = table(name, subindex, full_name, floor_name, ...
  id_section_list, type_name, idstory, type, idmaterial, ...
  idznominal, idvar, rank, dimension);

return
end
