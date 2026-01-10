function story = set_story_diff_height_block(dbc, story)
%set_story_diff_height_block - 標準階高と梁心の差を読み込む

nstory = size(story,1);

% セクションの存在確認（bidが0ならブロックが存在しない）
if dbc.bid('name=標準階高と梁心の差') == 0
  story.diff_height_direct = NaN(nstory, 1);

  return
end

data = dbc.get_data_block('標準階高と梁心の差');
n = size(data,1);

% 配列の初期化（NaN=未指定）
diff_height_direct = NaN(nstory, 1);

% データの読み込み
for i = 1:n
  story_name = tochar(data{i,1});
  distance = data{i,2};

  % 層番号の検索
  idx = find(matches(story.name, story_name));
  if isempty(idx)
    error('層 %s が見つかりません (標準階高と梁心の差)', story_name);
  end

  % 符号を反転して格納（SS7: 正 → YLAB内部: 負）
  diff_height_direct(idx) = -distance;
end

story.diff_height_direct = diff_height_direct;

return
end
