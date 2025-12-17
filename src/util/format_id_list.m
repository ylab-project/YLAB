function ids_text = format_id_list(ids)
%FORMAT_ID_LIST 数値ID配列をカンマ区切り文字列に変換
% 概要: 数値ベクトル ids をカンマ区切り文字列に変換します。
% 入力: ids - 数値ベクトル
% 出力: ids_text - カンマ区切り文字列
% See also: strjoin

if isempty(ids)
  ids_text = '';
  return
end

ids_cell = arrayfun(@num2str, ids, 'UniformOutput', false);
ids_text = strjoin(ids_cell, ', ');

return
end
