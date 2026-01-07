function rigid_zone = set_member_column_rigid_zone_block(dbc, com)
%set_member_column_rigid_zone_block - 柱の剛域（直接入力）を読み込む
%
% CSVデータ構造:
% 階1, 階2, X軸1, X軸2, Y軸1, Y軸2, 断面方向, 柱頭(mm), 柱脚(mm)
%
% 出力:
%   rigid_zone - 構造体
%     .x  - X方向剛域 [nmec×2]（列1:柱脚, 列2:柱頭）
%     .y  - Y方向剛域 [nmec×2]（列1:柱脚, 列2:柱頭）
%     NaN: 自動計算を使用、数値: 直接入力値

data = dbc.get_data_block('柱の剛域');
n = size(data,1);

% 共通配列
baseline = com.baseline;
story = com.story;
member_column = com.member.column;
nmec = com.nmec;

% 出力配列の初期化（NaN = 自動計算を使用）
rigid_zone.x = nan(nmec, 2);  % [柱脚, 柱頭]
rigid_zone.y = nan(nmec, 2);  % [柱脚, 柱頭]

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
  direction = tochar(data{i,7});    % 断面方向
  lr_top = data{i,8};               % 柱頭(mm)
  lr_bottom = data{i,9};            % 柱脚(mm)

  % 範囲内の柱を特定（既存関数を活用）
  idmec_list = find_idcolumn_from_idxyz(...
    idx_search(i,:), idy_search(i,:), idz_search(i,:), member_column);

  % 剛域値の適用
  for j = 1:length(idmec_list)
    im = idmec_list(j);

    switch direction
      case '全方向'
        rigid_zone.x(im, 1) = lr_bottom;  % X方向柱脚
        rigid_zone.x(im, 2) = lr_top;     % X方向柱頭
        rigid_zone.y(im, 1) = lr_bottom;  % Y方向柱脚
        rigid_zone.y(im, 2) = lr_top;     % Y方向柱頭
      case 'X方向'
        rigid_zone.x(im, 1) = lr_bottom;
        rigid_zone.x(im, 2) = lr_top;
      case 'Y方向'
        rigid_zone.y(im, 1) = lr_bottom;
        rigid_zone.y(im, 2) = lr_top;
    end
  end
end

return
end
