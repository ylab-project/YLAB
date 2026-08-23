function tf = is_legacy_nodal_force_block(block)
%is_legacy_nodal_force_block - 節点荷重ブロックが従来形式かを判定する
%
%   tf = is_legacy_nodal_force_block(block) は、`節点荷重`ブロックの
%   最初のデータ行の第1列だけを参照し、`DL`・`LL`・空欄なら新形式、
%   それ以外なら従来形式と判定する。判定はブロック単位で一度だけ
%   行い、2行目以降では再判定しない（内部設計4章）。データ行がない
%   ブロックは従来形式として扱う。
%
%   入力引数:
%     block - get_data_blocks が返すブロック構造体
%
%   出力引数:
%     tf - 従来形式なら true
tf = true;
data = block.data;
if isempty(data)
  return
end
first = tochar(data{1, 1});
tf = ~(isempty(first) || any(strcmp(first, {'DL', 'LL'})));

return
end
