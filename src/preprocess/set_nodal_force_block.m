function [nodal_force, issues] = set_nodal_force_block(blocks, dbc, com)
%set_nodal_force_block - 節点系荷重の値と配置指定を正規化する
%
%   [nodal_force, issues] = set_nodal_force_block(blocks, dbc, com) は、
%   新形式と判定された`節点荷重`ブロックと`応力計算用特殊荷重(節点)`を
%   解釈し、荷重値と未解決の配置指定を持つテーブルを返す。
%   対象節点の解決と解析・重量への加算は行わない。
%   `節点荷重`は形式共用のため列定義を持たず、数値列はここで
%   正規化する（解釈できない値はエラーで読込を停止する）。従来
%   形式の`節点荷重`は set_legacy_nodal_force_block が読む。
%
%   入力引数:
%     blocks - is_legacy_nodal_force_block で新形式と判定された
%              `節点荷重`ブロックの構造体配列
%     dbc    - data_block_classオブジェクト
%     com    - 共通オブジェクト
%
%   出力引数:
%     nodal_force - 配置指定・ilc・6成分・重量分類・入力位置を持つ
%                   未解決の節点荷重テーブル
%     issues - 入力警告。反映件数は作用先解決後に確定する
special_blocks = dbc.get_data_blocks('応力計算用特殊荷重(節点)');
nforce_max = 0;
for ib = 1:length(blocks)
  nforce_max = nforce_max + size(blocks(ib).data, 1);
end
for ib = 1:length(special_blocks)
  nforce_max = nforce_max + size(special_blocks(ib).data, 1);
end

% 各列を入力行数の上限まで確保し、有効な入力行まで切り詰める
selector = cell(nforce_max, 3);
input_value = cell(nforce_max, 1);
ilc = zeros(nforce_max, 1);
f = zeros(nforce_max, 6);
wclass = zeros(nforce_max, 1);
wusage = zeros(nforce_max, 1);
wtype = zeros(nforce_max, 1);
is_cantilever = false(nforce_max, 1);
block_name = cell(nforce_max, 1);
iblock = zeros(nforce_max, 1);
irow = zeros(nforce_max, 1);
csv_row = zeros(nforce_max, 1);
nforce = 0;
issues = empty_input_issues();
ilc_gp = find_ilc_long_term(com.loadcase);

for ib = 1:length(blocks)
  block = blocks(ib);
  data = block.data;
  for ir = 1:size(data, 1)
    csv_line = block.origrows(ir);
    names = cell(1, 3);
    for k = 1:3
      names{k} = tochar(get_cell_value(data, ir, k));
    end
    [head, ilc_line, issues] = read_weight_head(names, ilc_gp, ...
      '節点荷重', ib, csv_line, issues);
    target = cell(1, 3);
    for k = 1:3
      target{k} = tochar(get_cell_value(data, ir, k + 3));
    end
    if head.is_valid && any(cellfun(@is_all_token, target))
      issues = add_input_issue(issues, 'ElementLoadAllNotSupported', ...
        '', '節点荷重', ib, csv_line, strjoin(target, '/'), 1, 0, 1, '');
      head.is_valid = false;
    end
    if ~head.is_valid
      continue
    end

    f6 = read_force_components(data, ir, 7, '節点荷重', csv_line);
    nforce = nforce + 1;
    selector(nforce, :) = target;
    input_value{nforce} = strjoin(names, '/');
    ilc(nforce) = ilc_line;
    f(nforce, :) = f6;
    wclass(nforce) = head.wclass;
    wusage(nforce) = head.wusage;
    wtype(nforce) = head.wtype;
    block_name{nforce} = '節点荷重';
    iblock(nforce) = ib;
    irow(nforce) = ir;
    csv_row(nforce) = csv_line;
  end
end
for ib = 1:length(special_blocks)
  block = special_blocks(ib);
  data = block.data;
  label = '応力計算用特殊荷重(節点)';
  for ir = 1:size(data, 1)
    csv_line = block.origrows(ir);
    case_name = tochar(get_cell_value(data, ir, 1));
    [ilc_line, issues] = read_loadcase_head(case_name, com, label, ...
      ib, csv_line, issues);
    if ilc_line == 0
      continue
    end

    target = cell(1, 3);
    for k = 1:3
      target{k} = tochar(get_cell_value(data, ir, k + 1));
    end
    if any(cellfun(@is_all_token, target))
      issues = add_input_issue(issues, 'ElementLoadAllNotSupported', ...
        '', label, ib, csv_line, strjoin(target, '/'), 1, 0, 1, '');
      continue
    end
    f6 = read_force_components(data, ir, 5, label, csv_line);
    nforce = nforce + 1;
    selector(nforce, :) = target;
    input_value{nforce} = '';
    ilc(nforce) = ilc_line;
    f(nforce, :) = f6;
    block_name{nforce} = label;
    iblock(nforce) = ib;
    irow(nforce) = ir;
    csv_row(nforce) = csv_line;
  end
end

nodal_force = table(selector, input_value, ilc, f, wclass, wusage, ...
  wtype, is_cantilever, block_name, iblock, irow, csv_row);
nodal_force = nodal_force(1:nforce, :);

return
end


function f = read_force_components(data, irow, first_col, label, csv_row)
%read_force_components - 力とモーメント6成分を正規化する
%
%   f = read_force_components(data, irow, first_col, label, csv_row)
%   は、first_colから6列を数値化し、空欄を0とする。非数値なら停止する。
%
%   入力引数:
%     data - 入力セル配列
%     irow - ブロック内の行番号
%     first_col - 6成分の開始列番号
%     label - 入力ブロック名
%     csv_row - 元CSV行番号
%
%   出力引数:
%     f - 力とモーメント [1×6]。空欄は0、非数値は入力エラー

f = zeros(1, 6);
for k = 1:6
  [value, is_valid] = normalize_numeric_cell(get_cell_value(data, irow, ...
    first_col + k - 1));
  if ~is_valid
    throw_err('Input', 'InvalidNumericValue', irow, csv_row, ...
      sprintf('%s の %d 列目', label, first_col + k - 1));
  end
  if ~isnan(value)
    f(k) = value;
  end
end

return
end


function value = get_cell_value(data, irow, icol)
%get_cell_value - 入力セルを取り出す
%
%   value = get_cell_value(data, irow, icol)
%   は、指定した行・列の値を返し、入力列が足りない場合はmissingを返す。
%
%   入力引数:
%     data - 入力セル配列
%     irow - 行番号
%     icol - 列番号
%
%   出力引数:
%     value - セルの値。列が存在しない場合はmissing

if icol > size(data, 2)
  value = missing;
else
  value = data{irow, icol};
end

return
end
