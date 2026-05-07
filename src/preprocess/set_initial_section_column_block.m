function initial_section_column = set_initial_section_column_block( ...
  dbc, com)
%set_initial_section_column_block - S柱断面(仮定)ブロックの読み込み
%
%   initial_section_column = set_initial_section_column_block(dbc, com)
%   は、入力データの「S柱断面(仮定)」ブロックを読み込み、最適化開始
%   時の柱断面（仮定値）テーブルを返す。
%
%   入力引数:
%     dbc - データブロックコンテナ
%     com - 共通オブジェクト
%
%   出力引数:
%     initial_section_column - 仮定柱断面テーブル [n×5]
%       列: name, subindex, floor_name, full_name, dimension
%
%   備考:
%     - subindex の '-' は階番号(idfloor)に置換され、
%       set_section_column_block と整合する。
%     - dimension は鉄骨登録形状名 (cell of char)。

data = dbc.get_data_block('S柱断面(仮定)');
n = size(data,1);

% 階名
floor_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
end

% 層番号
idstory = zeros(n,1); iddd = 1:com.nstory;
for i=1:n
  idstory(i) = iddd(matches(com.story.floor_name, floor_name{i}));
end

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字（'-' は階番号に置換、set_section_column_block と整合）
subindex = cell(n,1);
full_name = cell(n,1);
idfloor = com.story.idfloor(idstory);
for i=1:n
  subindex{i} = make_subindex(data{i,3}, idfloor(i));
  full_name{i} = [subindex{i} name{i}];
end

% 鉄骨登録形状
dimension = cell(n,1);
for i=1:n
  dimension{i} = data{i,4};
end

% 結果の保存
initial_section_column = table(name, subindex , floor_name, full_name, ...
  dimension);
return
end
