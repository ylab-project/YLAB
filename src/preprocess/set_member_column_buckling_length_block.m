function column_buckling_K = set_member_column_buckling_length_block( ...
  dbc, com)
%set_member_column_buckling_length_block - 柱の座屈長さ係数（直接入力）を読み込む
%
% CSVデータ構造:
% 階1, 階2, X軸1, X軸2, Y軸1, Y軸2, 断面方向, K
%
% 出力:
%   column_buckling_K - 構造体
%     .Kx - X方向の座屈長さ係数 [nmec×1]
%     .Ky - Y方向の座屈長さ係数 [nmec×1]
%     NaN: 自動計算を使用、数値: 直接入力値

data = dbc.get_data_block('柱の座屈長さ係数');

% 共通配列
baseline = com.baseline;
story = com.story;
member_column = com.member.column;
nmec = size(member_column.idx,1);

% 出力配列の初期化（NaN = 自動計算を使用）
column_buckling_K.Kx = nan(nmec, 1);
column_buckling_K.Ky = nan(nmec, 1);

% ヘッダ行（K列が数値でない行）を除外
if isempty(data)
  return
end
is_data_row = false(size(data,1),1);
for i = 1:size(data,1)
  is_data_row(i) = isnumeric(data{i,8}) && ~isnan(data{i,8});
end
data = data(is_data_row,:);
n = size(data,1);
if n == 0
  return
end

% 層名・通り名の抽出（範囲指定用に2列）
floor_name = cell(n,2);
xcoord_name = cell(n,2);
ycoord_name = cell(n,2);
for i = 1:n
  floor_name{i,1} = tochar(data{i,1});   % 階1
  floor_name{i,2} = tochar(data{i,2});   % 階2
  xcoord_name{i,1} = tochar(data{i,3});  % X軸1
  xcoord_name{i,2} = tochar(data{i,4});  % X軸2
  ycoord_name{i,1} = tochar(data{i,5});  % Y軸1
  ycoord_name{i,2} = tochar(data{i,6});  % Y軸2
end

% 通り名から通り番号への変換（既存関数を活用）
[idx_search, idy_search, idz_search] = find_idxyz_column(...
  floor_name, xcoord_name, ycoord_name, baseline, story);

% データの読み取りと適用
for i = 1:n
  direction = tochar(data{i,7});    % 断面方向（'X' or 'Y'）
  K = data{i,8};                    % K値

  % 範囲内の柱を特定（既存関数を活用）
  idmec_list = find_idcolumn_from_idxyz(...
    idx_search(i,:), idy_search(i,:), idz_search(i,:), member_column);

  % K値の適用
  for j = 1:length(idmec_list)
    im = idmec_list(j);

    switch direction
      case 'X'
        column_buckling_K.Kx(im) = K;
      case 'Y'
        column_buckling_K.Ky(im) = K;
    end
  end
end

return
end
