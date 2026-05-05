function write_csv_from_cell(fid, head, body, modeSS7, auto_marker)
%write_csv_from_cell - セル配列をCSV形式でファイルに書き出す
%
%   write_csv_from_cell(fid, head, body, modeSS7, auto_marker) は、
%   head/body のセル配列を CSV 行として fid に出力する。body 最終列を
%   marker 列として扱い、marker が PRM.CONT_MARKER の行は継続行として
%   行末の <RE> を付けない（それ以外は PRM.ROW_END_MARKER を付与）。
%
%   auto_marker=true のときは、各物理行=1論理行（A パターン）として
%   body 末尾に空 marker 列を自動付加する。writer 側で marker 列を
%   持たずに済む。
%
%   入力引数:
%     fid         - ファイル識別子 (fopenで取得)
%     head        - ヘッダ部のセル配列（marker 列は持たない）
%     body        - データ部のセル配列（最終列が marker。
%                   auto_marker=true なら marker 列を持たない）
%     modeSS7     - SS7形式フラグ (省略時true、trueの場合<data>タグ挿入)
%     auto_marker - 自動 marker 付与フラグ (省略時false)。trueの場合
%                   各行末に <RE> を付与（A パターン）

if nargin < 4, modeSS7 = true; end
if nargin < 5, auto_marker = false; end

write_tab_(fid, head, false)
if modeSS7
  fprintf(fid, '<data>\n');
end
if auto_marker && ~isempty(body)
  body(:, end+1) = {''};
end
write_tab_(fid, body, true)

return
end

function write_tab_(fid, tab, has_marker)
%write_tab_ - セル配列をCSV出力（RFC 4180準拠のクォート処理）
%
%   write_tab_(fid, tab, has_marker) は、セル配列 tab を CSV 行として
%   fid に出力する。has_marker=true のとき、tab 最終列を marker として
%   扱い、marker が PRM.CONT_MARKER の行には行末の <RE> を付与しない。
%   それ以外の行（marker が空・未定義も含む）は PRM.ROW_END_MARKER を
%   付与する。
%   RFC 4180: カンマ/ダブルクォート/改行/空白を含むセルはダブルクォート
%   で囲み、値内のダブルクォートは "" にエスケープ（入出力で共通適用）。
%
%   入力引数:
%     fid        - ファイル識別子 (fopenで取得)
%     tab        - 出力対象のセル配列
%     has_marker - tab 最終列を marker 列として扱うかのフラグ

if isempty(tab)
  return
end

str = cellfun(@cell2str, tab, 'UniformOutput', false);
needs_q = cellfun(@(v) ~isempty(v) && contains(v, ...
  {',', '"', newline, char(13), ' '}), str);
str(needs_q) = cellfun(@(v) ['"' strrep(v, '"', '""') '"'], ...
  str(needs_q), 'UniformOutput', false);

if has_marker
  marker_col = str(:, end);
  bad = ~cellfun('isempty', marker_col) ...
    & ~strcmp(marker_col, PRM.CONT_MARKER);
  if any(bad)
    error('write_csv_from_cell:MarkerColumnHasData', ...
      ['marker 列に想定外の値があります（%d 行）。' ...
      '実データを最終列に書いていませんか？ 最初の例 (行 %d): "%s"'], ...
      sum(bad), find(bad, 1), marker_col{find(bad, 1)});
  end
  str = str(:, 1:end-1);
else
  marker_col = [];
end
notempty = ~cellfun('isempty', str);

n = size(tab, 1);
cont = PRM.CONT_MARKER;
re_suffix = [',' PRM.ROW_END_MARKER];
lines = cell(n, 1);
for i = 1:n
  if ~any(notempty(i, :))
    lines{i} = '';
    continue
  end
  line = strjoin(str(i, :), ',');
  if has_marker && ~strcmp(marker_col{i}, cont)
    lines{i} = [line re_suffix];
  else
    lines{i} = line;
  end
end
fprintf(fid, '%s\n', lines{:});

return
end

function s = cell2str(v)
%cell2str - セル値を文字列に変換
%
%   s = cell2str(v) は、セル配列の 1 要素 v を文字列に変換する。
%   空は空文字、数値/論理は '%g' 書式、文字はそのまま、その他は char
%   で変換する。
%
%   入力引数:
%     v - 変換対象の値（任意型）
%
%   出力引数:
%     s - 変換後の文字列

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
