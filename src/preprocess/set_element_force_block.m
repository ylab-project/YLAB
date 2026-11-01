function [element_force, issues] = set_element_force_block(dbc, com)
%set_element_force_block - 新形式線材荷重の値と配置指定を正規化する
%
%   [element_force, issues] = set_element_force_block(dbc, com) は、
%   要素荷重と応力計算用特殊荷重の梁・柱ブロックを読み込む。
%   値、荷重ケースと継続区間を正規化し、作用先の番号は確定しない。
%   重量の共通・ラーメン用は長期ケース、地震用はilc=0とする。
%
%   入力引数:
%     dbc - data_block_classオブジェクト
%     com - 共通オブジェクト
%
%   出力引数:
%     element_force - 配置指定・ilc・ar・M0・重量分類・入力位置を
%                     列に持つ未解決の線材荷重テーブル
%     issues - 入力警告。反映件数は作用先解決後に確定する
defs = get_block_definitions();
blocks_by_def = cell(length(defs), 1);
nforce_max = 0;
for idef = 1:length(defs)
  blocks_by_def{idef} = dbc.get_data_blocks(defs(idef).name);
  for ib = 1:length(blocks_by_def{idef})
    nforce_max = nforce_max + size(blocks_by_def{idef}(ib).data, 1);
  end
end

% 各列を入力行数の上限まで確保し、有効な入力行まで切り詰める
selector = cell(nforce_max, max([defs.comp_col] - [defs.target_col]));
is_continued = false(nforce_max, 1);
ilc = zeros(nforce_max, 1);
ar = zeros(nforce_max, 12);
M0 = zeros(nforce_max, 1);
M0y = zeros(nforce_max, 1);
M0z = zeros(nforce_max, 1);
quarter = nan(nforce_max, 4);
wclass = zeros(nforce_max, 1);
wusage = zeros(nforce_max, 1);
wtype = zeros(nforce_max, 1);
block_name = cell(nforce_max, 1);
iblock = zeros(nforce_max, 1);
irow = zeros(nforce_max, 1);
csv_row = zeros(nforce_max, 1);
nforce = 0;
issues = empty_input_issues();
ilc_gp = find_ilc_long_term(com.loadcase);

for idef = 1:length(defs)
  def = defs(idef);
  blocks = blocks_by_def{idef};
  for ib = 1:length(blocks)
    block = blocks(ib);
    data = block.data;
    nrow = size(data, 1);
    ir = 1;
    while ir <= nrow
      group = find_continuation_group(data, ir, def.cont_col);
      csv_head = block.origrows(group(1));

      names = data(group(1), def.target_col:def.comp_col - 1);
      names = cellfun(@tochar, names, 'UniformOutput', false);
      [ilc_group, head, is_valid, issues] = read_group_head(data, ...
        group(1), def, com, ilc_gp, csv_head, issues, ib);
      if is_valid && any(cellfun(@is_all_token, names))
        issues = add_input_issue(issues, 'ElementLoadAllNotSupported', ...
          '', def.name, ib, csv_head, strjoin(names, '/'), 1, 0, 1, '');
        is_valid = false;
      end
      if ~is_valid
        ir = group(end) + 1;
        continue
      end
      for iseg = 1:length(group)
        source_row = group(iseg);
        nforce = nforce + 1;
        [ar(nforce, :), M0(nforce), M0y(nforce), M0z(nforce), ...
          quarter(nforce, :)] = read_line_force(data, source_row, def);
        selector(nforce, 1:numel(names)) = names;
        is_continued(nforce) = iseg < length(group);
        ilc(nforce) = ilc_group;
        wclass(nforce) = head.wclass;
        wusage(nforce) = head.wusage;
        wtype(nforce) = head.wtype;
        block_name{nforce} = def.name;
        iblock(nforce) = ib;
        irow(nforce) = source_row;
        csv_row(nforce) = block.origrows(source_row);
      end
      ir = group(end) + 1;
    end
  end
end

element_force = table(selector, is_continued, ilc, ar, M0, M0y, M0z, ...
  quarter, wclass, wusage, wtype, block_name, iblock, irow, csv_row);
element_force = element_force(1:nforce, :);

return
end


function defs = get_block_definitions()
%get_block_definitions - 要素荷重4ブロックの列定義を返す
%
%   defs = get_block_definitions()
%   は、梁・柱の重量と特殊荷重について、配置指定と成分の列位置を得る。
%
%   入力引数:
%     なし
%
%   出力引数:
%     defs - element_force_layoutで定義した列位置と荷重種別

names = {'要素荷重(梁)', '要素荷重(柱)', '応力計算用特殊荷重(梁)', ...
  '応力計算用特殊荷重(柱)'};
defs = element_force_layout(names{1});
for k = 2:length(names)
  defs(k) = element_force_layout(names{k});
end

return
end


function group = find_continuation_group(data, first, cont_col)
%find_continuation_group - 継続指定Tで連結された入力行を取得する
%
%   group = find_continuation_group(data, first, cont_col)
%   は、firstから継続指定が終わる行までの行番号を入力順に返す。
%
%   入力引数:
%     data - 入力セル配列
%     first - グループ先頭行番号
%     cont_col - 継続指定の列番号
%
%   出力引数:
%     group - 入力順の行番号 [1×n]

group = first;
nrow = size(data, 1);
while group(end) < nrow && strcmp(tochar(data{group(end), cont_col}), 'T')
  group(end + 1) = group(end) + 1; %#ok<AGROW>
end

return
end


function [ilc, head, is_valid, issues] = read_group_head(data, ...
  irow1, def, com, ilc_gp, csv_row, issues, iblock)
%read_group_head - 先頭行の荷重ケースと分類を解釈する
%
%   [ilc, head, is_valid, issues] = read_group_head(data, ...
%   irow1, def, com, ilc_gp, csv_row, issues, iblock)
%   は、重量分類またはケース名を解釈し、後続行が継承する区分を返す。
%
%   入力引数:
%     data - 入力セル配列
%     irow1 - グループ先頭行番号
%     def - 列定義と荷重種別
%     com - 荷重ケースを持つ共通データ
%     ilc_gp - 長期荷重ケース番号
%     csv_row - 元CSV行番号
%     issues - 収集済みの入力警告
%     iblock - 同名ブロックの出現番号
%
%   出力引数:
%     ilc - 荷重ケース番号。無効時は0
%     head - 重量の分類、用途、種別と検証結果
%     is_valid - このグループを反映する場合はtrue
%     issues - 行頭の検証結果を追加した入力警告

head = struct('wclass', 0, 'wusage', 0, 'wtype', 0, ...
  'is_valid', true, 'unknown_type', false, 'is_unusual', false);
if def.is_weight
  names = cellfun(@tochar, data(irow1, 1:3), 'UniformOutput', false);
  [head, ilc, issues] = read_weight_head(names, ilc_gp, def.name, ...
    iblock, csv_row, issues);
  is_valid = head.is_valid;
else
  case_name = tochar(data{irow1, 1});
  [ilc, issues] = read_loadcase_head(case_name, com, def.name, ...
    iblock, csv_row, issues);
  is_valid = ilc > 0;
end

return
end


function [ar, M0, M0y, M0z, quarter] = read_line_force(data, irow, def)
%read_line_force - 線材荷重1行の成分と位置別の値を読む
%
%   [ar, M0, M0y, M0z, quarter] = read_line_force(data, irow, def)
%   は、defで指定した列から端部力と曲げモーメントの入力値を取り出す。
%
%   入力引数:
%     data - 入力セル配列
%     irow - 読込対象の行番号
%     def - 応力成分と位置値の列定義
%
%   出力引数:
%     ar - 両端の6成分を並べた荷重 [1×12]
%     M0 - 旧形式の中間荷重値
%     M0y, M0z - 部材軸ごとの中間荷重値
%     quarter - 1/4位置の成分 [1×4]。省略はNaN

comp_cols = def.comp_col:def.comp_col + 11;
ar = normalize_missing_zero(cell2mat(data(irow, comp_cols)));
M0 = 0;
if def.m0_col > 0
  M0 = normalize_missing_zero(data{irow, def.m0_col});
end
M0y = NaN;
M0z = NaN;
if def.m0y_col > 0
  M0y = data{irow, def.m0y_col};
  M0z = data{irow, def.m0y_col + 1};
end
quarter = nan(1, 4);
if def.quarter_col > 0
  quarter = cell2mat(data(irow, def.quarter_col:def.quarter_col + 3));
end

return
end
