function initial_section = read_initial_section_block(dbc, ...
  block_name, story_names)
%read_initial_section_block - 仮定断面ブロックを読み込む
%
%   initial_section = read_initial_section_block(dbc, block_name, ...
%     story_names) は、仮定断面ブロックを読み込み、符号、階・層に
%   対応する内部ID、鉄骨登録形状を持つ仮定断面テーブルを返す。
%
%   入力引数:
%     dbc         - データブロックコンテナ
%     block_name  - 仮定断面のブロック名
%     story_names - 内部IDの照合に使う階名または層名 [nstory×1]
%
%   出力引数:
%     initial_section - 仮定断面テーブル
%       主要列: full_name, idstory, dimension

data = dbc.get_data_block(block_name);
n = size(data,1);

idlist = 1:length(story_names);
full_name = cell(n,1);
idstory = zeros(n,1);
dimension = cell(n,1);
for i=1:n
  % 階名または層名から対応する内部IDを解決する
  idstory(i) = idlist(matches(story_names, tochar(data{i,1})));

  % 符号を組み立てる
  subindex = make_subindex(data{i,3});
  full_name{i} = [subindex tochar(data{i,2})];

  % 鉄骨登録形状
  dimension{i} = data{i,4};
end

initial_section = table(full_name, idstory, dimension);

return
end
