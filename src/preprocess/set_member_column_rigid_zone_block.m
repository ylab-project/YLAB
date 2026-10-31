function rigid_zone = set_member_column_rigid_zone_block(dbc, com)
%set_member_column_rigid_zone_block - 柱の剛域直接入力を読み込む
%
%   rigid_zone = set_member_column_rigid_zone_block(dbc, com) は、
%   CSVデータブロック「柱の剛域」から方向別の柱脚・柱頭剛域を
%   読み込み、解析用の分割前の入力柱ごとに直接入力値を返す。
%
%   入力引数:
%     dbc - データブロッククラスオブジェクト
%     com - 共通データ構造体
%
%   出力引数:
%     rigid_zone - 方向別の柱剛域直接入力
%       .x - X方向の柱脚・柱頭剛域 [nmec x 2] (mm)
%       .y - Y方向の柱脚・柱頭剛域 [nmec x 2] (mm)
%       .n - 材軸方向の柱脚・柱頭剛域 [nmec x 2] (mm)
%
%   備考:
%     - NaNは自動計算を使用することを表す。
%     - 入力値-1はSS7仕様の自動計算指定としてNaNへ変換する。

% 入力データと共通配列
data = dbc.get_data_block('柱の剛域');
n = size(data,1);
baseline = com.baseline;
story = com.story;
member_column = com.member.column;
nmec = com.nmec;

% 出力配列の初期化（NaNは自動計算を使用）
rigid_zone.x = nan(nmec,2);
rigid_zone.y = nan(nmec,2);
rigid_zone.n = nan(nmec,2);
if n == 0
  return
end

% 層名・通り名を範囲指定用の2列へ変換
floor_name = cell(n,2);
xcoord_name = cell(n,2);
ycoord_name = cell(n,2);
for i = 1:n
  floor_name{i,1} = tochar(data{i,1});
  floor_name{i,2} = tochar(data{i,2});
  xcoord_name{i,1} = tochar(data{i,3});
  xcoord_name{i,2} = tochar(data{i,4});
  ycoord_name{i,1} = tochar(data{i,5});
  ycoord_name{i,2} = tochar(data{i,6});
end
[idx_search, idy_search, idz_search] = find_idxyz_column( ...
  floor_name, xcoord_name, ycoord_name, baseline, story);

% 柱脚・柱頭の直接入力を入力柱へ設定
for i = 1:n
  direction = tochar(data{i,7});
  lr_top = data{i,8};
  lr_bottom = data{i,9};
  if isequal(lr_top, -1)
    lr_top = NaN;
  end
  if isequal(lr_bottom, -1)
    lr_bottom = NaN;
  end
  end_values = [lr_bottom lr_top];

  ids = find_idcolumn_from_idxyz(idx_search(i,:), idy_search(i,:), ...
    idz_search(i,:), member_column);
  switch direction
    case '全方向'
      rigid_zone.x(ids, :) = repmat(end_values, numel(ids), 1);
      rigid_zone.y(ids, :) = repmat(end_values, numel(ids), 1);
      rigid_zone.n(ids, :) = repmat(end_values, numel(ids), 1);
    case 'X方向'
      rigid_zone.x(ids, :) = repmat(end_values, numel(ids), 1);
    case 'Y方向'
      rigid_zone.y(ids, :) = repmat(end_values, numel(ids), 1);
    case '材軸方向'
      rigid_zone.n(ids, :) = repmat(end_values, numel(ids), 1);
  end
end

return
end
