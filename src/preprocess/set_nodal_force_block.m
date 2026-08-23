function nodal_force = set_nodal_force_block(blocks, dbc, com)
%set_nodal_force_block - 新形式の節点系荷重ブロックを読む
%
%   nodal_force = set_nodal_force_block(blocks, dbc, com) は、新形式
%   と判定された`節点荷重`ブロックと`応力計算用特殊荷重(節点)`を
%   解釈し、対象節点を解決した節点荷重テーブル（共通内部データ）を
%   返す入力アダプターである。解析・重量への加算は行わない。
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
%     nodal_force - idnode・ilc・6成分・重量分類・入力位置を列に持つ
%                   節点荷重テーブル
special_blocks = dbc.get_data_blocks('応力計算用特殊荷重(節点)');
nforce_max = 0;
for ib = 1:length(blocks)
  nforce_max = nforce_max + size(blocks(ib).data, 1);
end
for ib = 1:length(special_blocks)
  nforce_max = nforce_max + size(special_blocks(ib).data, 1);
end

% 各列を入力行数の上限まで確保し、対象節点の解決後に切り詰める
idnode = zeros(nforce_max, 1);
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
  apply_nodal_block();
end
for ib = 1:length(special_blocks)
  block = special_blocks(ib);
  apply_special_node_block();
end
report_input_issues(issues);

nodal_force = table(idnode, ilc, f, wclass, wusage, wtype, ...
  is_cantilever, block_name, iblock, irow, csv_row);
nodal_force = nodal_force(1:nforce, :);

return

  function apply_nodal_block()
    %apply_nodal_block - 新形式の節点荷重ブロックをテーブル行化する
    %
    %   親の block・ib を読み、列配列・nforce・issues を親ワーク
    %   スペースで直接更新するネスト関数である。
    data = block.data;
    for ir = 1:size(data, 1)
      csv_line = block.origrows(ir);
      names = cell(1, 3);
      for k = 1:3
        names{k} = tochar(get_cell_value(data, ir, k));
      end
      nissue_head = length(issues);
      [head, ilc_line, issues] = read_weight_head(names, ilc_gp, ...
        '節点荷重', ib, csv_line, issues);
      if ~head.is_valid
        continue
      end

      f6 = read_force_components(data, ir, 7, '節点荷重', csv_line);
      [id_found, issues] = resolve_node_target(data, ir, 4, com, ...
        csv_line, issues, '節点荷重', ib);
      if id_found == 0
        for iissue = nissue_head + 1:length(issues)
          if issues(iissue).applied_count > 0
            issues(iissue).applied_count = 0;
            issues(iissue).unapplied_count = issues(iissue).input_count;
          end
        end
        continue
      end
      nforce = nforce + 1;
      idnode(nforce) = id_found;
      ilc(nforce) = ilc_line;
      f(nforce, :) = f6;
      wclass(nforce) = head.wclass;
      wusage(nforce) = head.wusage;
      wtype(nforce) = head.wtype;
      block_name{nforce} = '節点荷重';
      iblock(nforce) = ib;
      irow(nforce) = ir;
      csv_row(nforce) = csv_line;
      if head.wtype == PRM.WTYPE_FOUNDATION
        issues = check_foundation_support(id_found, com, '節点荷重', ...
          ib, csv_line, strjoin(names, '/'), issues);
      end
    end

    return
  end

  function apply_special_node_block()
    %apply_special_node_block - 応力計算用特殊荷重(節点)を行化する
    %
    %   親の block・ib を読み、列配列・nforce・issues を親ワーク
    %   スペースで直接更新するネスト関数である。
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

      f6 = read_force_components(data, ir, 5, label, csv_line);
      [id_found, issues] = resolve_node_target(data, ir, 2, com, ...
        csv_line, issues, label, ib);
      if id_found == 0
        continue
      end
      nforce = nforce + 1;
      idnode(nforce) = id_found;
      ilc(nforce) = ilc_line;
      f(nforce, :) = f6;
      block_name{nforce} = label;
      iblock(nforce) = ib;
      irow(nforce) = ir;
      csv_row(nforce) = csv_line;
    end

    return
  end
end


function f = read_force_components(data, irow, first_col, label, csv_row)
%read_force_components - 力・モーメント6成分を正規化する（空欄=0）
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


function [idnode, issues] = resolve_node_target(data, ...
  irow, first_col, com, csv_row, issues, block_name, iblock)
%resolve_node_target - 層・X軸・Y軸の指定から対象節点を解決する
idnode = 0;
names = cell(1, 3);
for k = 1:3
  names{k} = tochar(get_cell_value(data, irow, first_col + k - 1));
end
input_value = strjoin(names, '/');
if any(cellfun(@is_all_token, names))
  issues = add_input_issue(issues, 'ElementLoadAllNotSupported', '', ...
    block_name, iblock, csv_row, input_value, 1, 0, 1, '');
  return
end
idnode = find_idnode_from_names(names{1}, names{2}, names{3}, com);
if idnode == 0
  issues = add_input_issue(issues, 'ElementLoadNodeNotFound', '', ...
    block_name, iblock, csv_row, input_value, 1, 0, 1, '');
  return
end

return
end


function value = get_cell_value(data, irow, icol)
%get_cell_value - 列不足の行では空欄として missing を返す
if icol > size(data, 2)
  value = missing;
else
  value = data{irow, icol};
end

return
end
