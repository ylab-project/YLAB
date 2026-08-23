function element_force = set_element_force_block(dbc, com)
%set_element_force_block - 新形式の線材荷重ブロックを読む
%
%   element_force = set_element_force_block(dbc, com) は、
%   `要素荷重(梁)`・`要素荷重(柱)`・`応力計算用特殊荷重(梁)`・
%   `応力計算用特殊荷重(柱)`の各ブロックを解釈し、対象を全体部材
%   番号の直列セグメント列へ解決した線材荷重テーブル（共通内部
%   データ）を返す入力アダプターである。解析・重量への加算は
%   行わない。重量ブロックの共通・ラーメン用の行は長期解析対象
%   （G+P）、`地震用`の行は解析非計上（ilc=0）とする。
%
%   入力引数:
%     dbc - data_block_classオブジェクト
%     com - 共通オブジェクト
%
%   出力引数:
%     element_force - idme・ilc・ar・M0・位置値・重量分類・入力位置を
%                     列に持つ線材荷重テーブル
defs = get_block_definitions();
blocks_by_def = cell(length(defs), 1);
nforce_max = 0;
for idef = 1:length(defs)
  blocks_by_def{idef} = dbc.get_data_blocks(defs(idef).name);
  for ib = 1:length(blocks_by_def{idef})
    nforce_max = nforce_max + size(blocks_by_def{idef}(ib).data, 1);
  end
end

% 各列を入力行数の上限まで確保し、解析対象の解決後に切り詰める
idme = zeros(nforce_max, 1);
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
    apply_block();
  end
end
report_input_issues(issues);

element_force = table(idme, ilc, ar, M0, M0y, M0z, quarter, ...
  wclass, wusage, wtype, block_name, iblock, irow, csv_row);
element_force = element_force(1:nforce, :);

return

  function apply_block()
    %apply_block - 一つのブロックを行グループ単位でテーブル行化する
    %
    %   親の block・ib・def を読み、列配列・nforce・issues を親
    %   ワークスペースで直接更新するネスト関数である。
    data = block.data;
    nrow = size(data, 1);
    ntarget = 3;
    if strcmp(def.kind, 'girder')
      ntarget = 4;
    end
    last_col = def.target_col + ntarget - 1;
    ir = 1;
    while ir <= nrow
      group = find_continuation_group(data, ir, def.cont_col);
      data = update_group_head(data, group, last_col);
      csv_head = block.origrows(group(1));

      % 行頭警告は対象解決後に最終的な反映件数へ補正する
      nissue_head = length(issues);
      [ilc_group, head, is_valid, issues] = read_group_head(data, ...
        group(1), def, com, ilc_gp, csv_head, issues, ib);
      if ~is_valid
        ir = group(end) + 1;
        continue
      end

      % 対象の解決（配置ブロックと同じ指定）
      selector = data(group(1), def.target_col:last_col);
      [chain, issues] = resolve_group_target(selector, def.kind, com, ...
        csv_head, issues, def.name, ib);
      if isempty(chain)
        for iissue = nissue_head + 1:length(issues)
          if issues(iissue).applied_count > 0
            issues(iissue).applied_count = 0;
            issues(iissue).unapplied_count = issues(iissue).input_count;
          end
        end
        ir = group(end) + 1;
        continue
      end

      % セグメントと行グループの順対応（不足・過剰は残りを未反映）
      napply = min(length(chain), length(group));
      input_value = sprintf('入力行%d/要素%d', length(group), ...
        length(chain));
      if length(chain) > length(group)
        issues = add_input_issue(issues, 'ElementLoadContRowMissing', ...
          '', def.name, ib, csv_head, input_value, 1, napply, ...
          length(chain) - napply, '');
      elseif length(chain) < length(group)
        issues = add_input_issue(issues, 'ElementLoadContRowExtra', ...
          '', def.name, ib, csv_head, input_value, 1, napply, ...
          length(group) - napply, '');
      end
      for iseg = 1:napply
        source_row = group(iseg);
        nforce = nforce + 1;
        [ar(nforce, :), M0(nforce), M0y(nforce), M0z(nforce), ...
          quarter(nforce, :)] = read_line_force(data, source_row, def);
        idme(nforce) = chain(iseg);
        ilc(nforce) = ilc_group;
        wclass(nforce) = head.wclass;
        wusage(nforce) = head.wusage;
        wtype(nforce) = head.wtype;
        block_name{nforce} = def.name;
        iblock(nforce) = ib;
        irow(nforce) = source_row;
        csv_row(nforce) = block.origrows(source_row);
      end
      if head.wtype == PRM.WTYPE_FOUNDATION
        applied = chain(1:napply);
        property = com.member.property;
        endpoint = [property.idnode1(applied), property.idnode2(applied)];
        issues = check_foundation_support(endpoint, com, def.name, ...
          ib, csv_head, mat2str(applied), issues);
      end
      ir = group(end) + 1;
    end

    return
  end
end


function defs = get_block_definitions()
%get_block_definitions - 新形式線材ブロックの列定義を返す
%
%   defs = get_block_definitions() は、対象4ブロックの列位置定義を
%   element_force_layout から取得して並べる。
names = {'要素荷重(梁)', '要素荷重(柱)', '応力計算用特殊荷重(梁)', ...
  '応力計算用特殊荷重(柱)'};
defs = element_force_layout(names{1});
for k = 2:length(names)
  defs(k) = element_force_layout(names{k});
end

return
end


function group = find_continuation_group(data, first, cont_col)
%find_continuation_group - 継続Tで連結された行グループを取得する
group = first;
nrow = size(data, 1);
while group(end) < nrow && strcmp(tochar(data{group(end), cont_col}), 'T')
  group(end + 1) = group(end) + 1; %#ok<AGROW>
end

return
end


function data = update_group_head(data, group, last_col)
%update_group_head - 継続行の行頭・対象列の空欄へ1行目の値を適用
for k = 2:length(group)
  for icol = 1:last_col
    if isempty(tochar(data{group(k), icol}))
      data(group(k), icol) = data(group(1), icol);
    end
  end
end

return
end


function [ilc, head, is_valid, issues] = read_group_head(data, ...
  irow1, def, com, ilc_gp, csv_row, issues, iblock)
%read_group_head - 行グループ1行目の行頭を解釈する
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


function [chain, issues] = resolve_group_target(selector, ...
  kind, com, csv_row, issues, block_name, iblock)
%resolve_group_target - 対象指定をセグメント列へ解決する
chain = zeros(1, 0);
names = cellfun(@tochar, selector, 'UniformOutput', false);
input_value = strjoin(names, '/');
if any(cellfun(@is_all_token, names))
  issues = add_input_issue(issues, 'ElementLoadAllNotSupported', '', ...
    block_name, iblock, csv_row, input_value, 1, 0, 1, '');
  return
end
if strcmp(kind, 'girder')
  [chain, ambiguous] = find_idme_from_girder_layout(names{1}, ...
    names{2}, names{3}, names{4}, com);
else
  [chain, ambiguous] = find_idme_from_column_layout(names{1}, ...
    names{2}, names{3}, com);
end
if ambiguous
  issues = add_input_issue(issues, 'ElementLoadAmbiguousChain', '', ...
    block_name, iblock, csv_row, input_value, 1, 0, 1, '');
  return
end
if isempty(chain)
  issues = add_input_issue(issues, 'ElementLoadNoTarget', '', ...
    block_name, iblock, csv_row, input_value, 1, 0, 1, '');
  return
end

return
end


function [ar, M0, M0y, M0z, quarter] = read_line_force(data, irow, def)
%read_line_force - 線材荷重1行の応力成分と位置値を読む
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
