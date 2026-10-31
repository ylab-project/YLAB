function [isthrough, idconnected] = ...
  set_member_column_through_block(dbc, com)
%set_member_column_through_block - 一本部材指定と柱の接続関係を設定
%
%   [isthrough, idconnected] =
%     set_member_column_through_block(dbc, com) は、入力の
%   「通し柱」指定を端部フラグに記録し、同じ位置で柱頭と柱脚が
%   接する柱を接続する。解析用の分割前の入力柱を対象とする。
%
%   入力引数:
%     dbc - 入力データブロック
%     com - 共通データ構造体
%
%   出力引数:
%     isthrough   - 入力で一本部材指定された端部 [nmec×2] logical
%                   列順は柱脚、柱頭
%     idconnected - 柱頭側の接続先の柱番号 [nmec×1]
%                   0は接続先なし

% 入力で指定された位置を通り番号へ変換する
data = dbc.get_data_block('通し柱');
n = size(data, 1);
baseline = com.baseline;
column = com.member.column;
column_idx = column.idx;
column_idy = column.idy;
column_idz = column.idz;
nmec = com.nmec;
story_name = cell(n, 1);
coord_name = cell(n, 2);
for i = 1:n
  story_name{i} = tochar(data{i, 1});
  coord_name(i, :) = tochar(data(i, 2:3));
end
[idx, idy, idz] = find_idxyz_node(story_name, coord_name, baseline);

% 入力位置ごとに、柱脚(j=1)と柱頭(j=2)が一致する柱を検索し、
% 端部フラグと入力由来の接続を同じ照合結果から設定する
isthrough = false(nmec, 2);
idconnected = zeros(nmec, 1);
for i = 1:n
  idc = zeros(1, 2);
  for j = 1:2
    id = find(column_idx(:, j) == idx(i) & column_idy(:, j) == idy(i) ...
      & column_idz(:, j) == idz(i));
    if ~isempty(id)
      idc(j) = id;
      isthrough(id, j) = true;
    end
  end
  if all(idc > 0)
    idconnected(idc(2)) = idc(1);
  end
end

return
end
