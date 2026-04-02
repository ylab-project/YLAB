function write_csv_from_cell(fid, head, body, modeSS7)
%write_csv_from_cell - セル配列をCSV形式でファイルに書き出す
%
% 入力:
%   fid     - ファイル識別子 (fopenで取得)
%   head    - ヘッダー部のセル配列
%   body    - データ部のセル配列
%   modeSS7 - SS7形式フラグ (省略時true、trueの場合<data>タグを挿入)

if nargin==3
  modeSS7 = true;
end

write_csv_from_cell_(fid, head)
if modeSS7
  fprintf(fid, '<data>\n');
end
write_csv_from_cell_(fid, body)

return
end

function write_csv_from_cell_(fid, tab)
%write_csv_from_cell_ - セル配列をCSV出力する内部関数
%
% RFC 4180準拠のエスケープ処理を行う:
%   - カンマ、ダブルクォート、改行を含む値はダブルクォートで囲む
%   - 空白を含む値もダブルクォートで囲む
%   - 値内のダブルクォートは "" にエスケープ
%   - 入力(SS7→YLAB)・出力(YLAB→SS7)とも本ルールを適用する

if isempty(tab)
  return
end
[n, ~] = size(tab);

% 全セルを文字列化
str = cellfun(@cell2str, tab, 'UniformOutput', false);

% RFC 4180クォート処理（一括）
needs_q = cellfun(@(v) ~isempty(v) ...
  & contains(v, {',', '"', newline, char(13), ' '}), str);
str(needs_q) = cellfun(@(v) ['"' strrep(v, '"', '""') '"'], ...
  str(needs_q), 'UniformOutput', false);

% 空行判定（全セルが空の行はスキップ）
notempty = ~cellfun('isempty', str);

% 行ごとにjoinして一括出力
lines = cell(n, 1);
for i = 1:n
  if ~any(notempty(i, :))
    lines{i} = '';
  else
    lines{i} = strjoin(str(i, :), ',');
  end
end
fprintf(fid, '%s\n', lines{:});

return
end

function s = cell2str(v)
%cell2str - セル値を文字列に変換
if isempty(v)
  s = '';
elseif isnumeric(v) || islogical(v)
  s = sprintf('%g', v);
elseif ischar(v)
  s = v;
else
  s = char(v);
end
return
end

