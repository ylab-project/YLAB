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
%write_csv_from_cell_ - セル配列を1行ずつCSV出力する内部関数
%
% RFC 4180準拠のエスケープ処理を行う:
%   - カンマ、ダブルクォート、改行を含む値はダブルクォートで囲む
%   - 空白を含む値もダブルクォートで囲む
%   - 値内のダブルクォートは "" にエスケープ
%   - 入力(SS7→YLAB)・出力(YLAB→SS7)とも本ルールを適用する

[n,m] = size(tab);

% 空行の判定 (全セルが空の行はスキップ対象)
isempty_row = true(1,n);
for i=1:n
  for j=1:m
    if ~isempty(tab{i,j})
      isempty_row(i) = false;
    end
  end
end

% 各行を出力
for i=1:n
  if isempty_row(i)
    continue
  end
  for j=1:m
    % 最終列以外はカンマ区切り
    if j==m
      delimeter = '';
    else
      delimeter = ',';
    end
    if isnumeric(tab{i,j})
      fprintf(fid, ['%g' delimeter], tab{i,j});
    else
      val = tab{i,j};
      % カンマ、ダブルクォート、改行、空白を含む場合はクォートで囲む
      if contains(val, {',', '"', newline, char(13), ' '})
        val = ['"' strrep(val, '"', '""') '"'];
      end
      fprintf(fid, ['%s' delimeter], val);
    end
  end
  fprintf(fid, '\n');
end

return
end

