function element_load = set_frame_element_load_block(dbc, com)
%set_frame_element_load_block - 要素荷重をFRAME部材へ割り当てる
%
%   element_load = set_frame_element_load_block(dbc, com) は、同名の
%   要素荷重ブロックを属性付きで読み取り、固定端力、位置応力および
%   分類済み重量の入力レコードへ分離する。
%
%   入力引数:
%     dbc - data_block_classオブジェクト
%     com - 節点、部材、荷重ケースを保持する共通構造体
%
%   出力引数:
%     element_load - 解析用固定端力、位置応力、重量入力の構造体

nme = com.nme;
nlc = com.nlc;

element_load.analysis_ar = zeros(nme, 12, nlc);
element_load.M0 = zeros(nme, nlc);
element_load.weight_ar = zeros(nme, 12, length(PRM.ELOAD_CASE_NAMES), ...
  length(PRM.ELOAD_TYPE_NAMES));
element_load.position = empty_position_records();
element_load.stats = struct('applied_rows', 0, 'warning_count', 0);
blocks = dbc.get_data_blocks('要素荷重');
element_load.has_input = ~isempty(blocks);
issues = empty_issue_records();

% 対象部材チェーンは com のみに依存するため、1回だけ構築して
% 接続順まで確定する
[chains, order_ambiguous] = order_nominal_chains( ...
  build_nominal_chains(com), com.member.property);
for iblock = 1:length(blocks)
  block = blocks(iblock);
  [attribute, issues] = read_attributes(block, issues);
  if ~strcmp(attribute.element, 'FRAME')
    continue
  end
  [weight_case, weight_type, issues] = resolve_weight_attributes( ...
    attribute, block.header_origrow, issues);
  [element_load, issues] = apply_block(element_load, block, com, ...
    chains, order_ambiguous, weight_case, weight_type, issues);
end

element_load.stats.warning_count = length(issues);
report_issues(issues);

return
end

function records = empty_position_records()
%empty_position_records - 位置応力入力レコードの空構造体を返す
records = struct('idme', {}, 'ilc', {}, 'ar', {}, 'M0', {}, ...
  'quarter', {}, 'csv_row', {});

return
end

function issues = empty_issue_records()
%empty_issue_records - 警告集約レコードの空構造体を返す
issues = struct('id', {}, 'detail', {}, 'row', {});

return
end

function report_issues(issues)
%report_issues - 警告IDと詳細ごとに件数とCSV行を集約して通知する
if isempty(issues)
  return
end
keys = strcat({issues.id}, '|', {issues.detail});
[~, ifirst, igroup] = unique(keys, 'stable');
for ikey = 1:length(ifirst)
  sample = issues(ifirst(ikey));
  target = igroup == ikey;
  rows = unique([issues(target).row]);
  detail_args = {};
  if ~isempty(sample.detail)
    detail_args = {sample.detail};
  end
  throw_warn('Input', sample.id, detail_args{:}, nnz(target), ...
    mat2str(rows));
end

return
end

function [attribute, issues] = read_attributes(block, issues)
%read_attributes - ブロック属性を順序非依存で読み取る
attribute = struct('element', 'FRAME', 'case_name', '', ...
  'type_name', '', 'has_type', false);
attributes = block.attributes;
for iattr = 1:size(attributes, 1)
  key = attributes{iattr, 1};
  value = attributes{iattr, 2};
  switch key
    case 'element'
      attribute.element = upper(value);
    case 'case'
      attribute.case_name = upper(value);
    case 'type'
      attribute.type_name = value;
      attribute.has_type = true;
    otherwise
      issues = add_issue(issues, 'ElementLoadUnknownAttribute', ...
        key, block.header_origrow);
  end
end
if ~ismember(attribute.element, {'FRAME'})
  issues = add_issue(issues, 'ElementLoadUnknownElement', ...
    attribute.element, block.header_origrow);
end

return
end

function [case_id, type_id, issues] = resolve_weight_attributes( ...
  attribute, csv_row, issues)
%resolve_weight_attributes - caseとtypeを重量プールへ対応付ける
case_id = find(strcmp(PRM.ELOAD_CASE_NAMES, attribute.case_name), 1);
if isempty(case_id)
  case_id = 0;
  if ~isempty(attribute.case_name)
    issues = add_issue(issues, 'ElementLoadUnknownCase', ...
      attribute.case_name, csv_row);
  elseif attribute.has_type
    issues = add_issue(issues, 'ElementLoadUnusedType', '', csv_row);
  end
end

type_id = 0;
if case_id > 0
  type_id = find(strcmp(PRM.ELOAD_TYPE_NAMES, attribute.type_name), 1);
  if isempty(type_id)
    type_id = PRM.ELOAD_TYPE_FLOOR;
    if attribute.has_type
      issues = add_issue(issues, 'ElementLoadUnknownType', ...
        attribute.type_name, csv_row);
    end
  end
  is_ll_normal = ismember(type_id, [PRM.ELOAD_TYPE_FLOOR, ...
    PRM.ELOAD_TYPE_SPECIAL]);
  if case_id == PRM.ELOAD_CASE_LL && ~is_ll_normal
    issues = add_issue(issues, 'ElementLoadLlUnusualType', '', csv_row);
  end
end

return
end

function [element_load, issues] = apply_block(element_load, block, ...
  com, chains, order_ambiguous, weight_case, weight_type, issues)
%apply_block - 一つの要素荷重ブロックを物理部材へ適用する
data = block.data;
nrow = size(data, 1);
irow = 1;
while irow <= nrow
  [group, next_row, issues] = collect_group(data, irow, ...
    block.origrows, issues);
  inherited = inherit_group_fields(data(group, :));
  targets = resolve_frame_chains(inherited(1, 2:7), com, chains);
  if order_ambiguous
    issues = add_issue(issues, 'ElementLoadAmbiguousChain', '', ...
      block.origrows(irow));
  end
  if isempty(targets)
    issues = add_issue(issues, 'ElementLoadNoTarget', '', ...
      block.origrows(irow));
    irow = next_row;
    continue
  end

  for ichain = 1:length(targets)
    chain = targets{ichain};
    napply = min(length(chain), length(group));
    if length(chain) > length(group)
      issues = add_issue(issues, 'ElementLoadContRowMissing', '', ...
        block.origrows(irow));
    elseif length(chain) < length(group)
      issues = add_issue(issues, 'ElementLoadContRowExtra', '', ...
        block.origrows(irow));
    end
    for isegment = 1:napply
      row_index = group(isegment);
      csv_row = block.origrows(row_index);
      [element_load, reflected, issues] = apply_record( ...
        element_load, inherited(isegment, :), chain(isegment), ...
        csv_row, com, weight_case, weight_type, issues);
      element_load.stats.applied_rows = ...
        element_load.stats.applied_rows + double(reflected);
    end
  end
  irow = next_row;
end

return
end

function [group, next_row, issues] = collect_group(data, first, ...
  origrows, issues)
%collect_group - Tで連結された入力行グループを取得する
group = first;
current = first;
while is_continued(data, current)
  if current == size(data, 1)
    issues = add_issue(issues, 'ElementLoadContRowMissing', '', ...
      origrows(current));
    break
  end
  current = current + 1;
  group(end + 1) = current; %#ok<AGROW>
end
next_row = current + 1;

return
end

function tf = is_continued(data, irow)
%is_continued - 正規化済み25列目の継続指定を判定する
tf = size(data, 2) >= 25 && strcmp(tochar(data{irow, 25}), 'T');

return
end

function data = inherit_group_fields(data)
%inherit_group_fields - 継続行の解析ケースと対象指定を主行から継承する
for irow = 2:size(data, 1)
  for icol = 1:7
    if isempty(tochar(data{irow, icol}))
      data{irow, icol} = data{1, icol};
    end
  end
end

return
end

function targets = resolve_frame_chains(selector, com, chains)
%resolve_frame_chains - 端点範囲に一致する部材チェーンを選択する
targets = cell(0, 1);
property = com.member.property;
for ichain = 1:length(chains)
  chain = chains{ichain};
  inode_i = property.idnode1(chain(1));
  inode_j = property.idnode2(chain(end));
  if matches_endpoint(inode_i, selector(1:3), com) && ...
      matches_endpoint(inode_j, selector(4:6), com)
    targets{end + 1, 1} = chain; %#ok<AGROW>
  end
end

return
end

function chains = build_nominal_chains(com)
%build_nominal_chains - 梁・柱の名目番号からFRAME部材群を作る
property = com.member.property;
nme = length(property.type);
chains = cell(0, 1);
singleton = false(nme, 1);
member_names = {'girder', 'column'};
for itype = 1:length(member_names)
  member = com.member.(member_names{itype});
  has_nominal = isstruct(member) && isfield(member, 'idnominal');
  if istable(member)
    has_nominal = ismember('idnominal', member.Properties.VariableNames);
  end
  if ~has_nominal
    for imember = 1:length(member.idme)
      idme = member.idme(imember);
      chains{end + 1, 1} = idme; %#ok<AGROW>
      singleton(idme) = true;
    end
    continue
  end
  nominal_id = member.idnominal(:, 1);
  ids = unique(nominal_id(nominal_id > 0), 'stable');
  for iid = 1:length(ids)
    target = nominal_id == ids(iid);
    segment_order = member.idnominal(target, 2);
    member_ids = member.idme(target);
    [~, order] = sort(segment_order);
    chain = member_ids(order)';
    chains{end + 1, 1} = chain; %#ok<AGROW>
    if isscalar(chain)
      singleton(chain) = true;
    end
  end
end
frame_ids = find(ismember(property.type, [PRM.COLUMN, PRM.GIRDER]) ...
  & ~singleton);
for iframe = 1:length(frame_ids)
  chains{end + 1, 1} = frame_ids(iframe); %#ok<AGROW>
end

return
end

function [chains, ambiguous] = order_nominal_chains(candidates, property)
%order_nominal_chains - 候補部材群を接続順に並べ、順序不定を記録する
chains = cell(0, 1);
ambiguous = false;
for icandidate = 1:length(candidates)
  [chain, is_ambiguous] = order_member_chain(candidates{icandidate}, ...
    property);
  ambiguous = ambiguous || is_ambiguous;
  if ~isempty(chain)
    chains{end + 1, 1} = chain; %#ok<AGROW>
  end
end

return
end

function [chain, ambiguous] = order_member_chain(ids, property)
%order_member_chain - 部材群を内部i端からj端へ一意に並べる
chain = zeros(1, 0);
ambiguous = false;
if isempty(ids)
  return
end
inode_i = property.idnode1(ids);
inode_j = property.idnode2(ids);
start = ids(~ismember(inode_i, inode_j));
if length(start) ~= 1
  ambiguous = true;
  return
end

chain = start;
while length(chain) < length(ids)
  current_node = property.idnode2(chain(end));
  next = ids(property.idnode1(ids) == current_node);
  next = setdiff(next, chain, 'stable');
  if length(next) ~= 1
    chain = zeros(1, 0);
    ambiguous = true;
    return
  end
  chain(end + 1) = next; %#ok<AGROW>
end

return
end

function tf = matches_endpoint(inode, selector, com)
%matches_endpoint - 節点が層・X軸・Y軸の各指定に含まれるか判定する
node = com.node;
match_z = matches_selector(node.zname{inode}, selector{1}, ...
  com.baseline.z.name);
match_x = matches_selector(node.xname{inode}, selector{2}, ...
  com.baseline.x.name);
match_y = matches_selector(node.yname{inode}, selector{3}, ...
  com.baseline.y.name);
tf = match_z && match_x && match_y;

return
end

function tf = matches_selector(actual, selector, ordered_names)
%matches_selector - 具体名、全指定または区切り範囲を照合する
token = strtrim(tochar(selector));
if is_all_token(token)
  tf = true;
  return
end
if strcmp(actual, token)
  tf = true;
  return
end

parts = split_range_token(token);
if length(parts) ~= 2
  tf = false;
  return
end
i1 = find(strcmp(ordered_names, parts{1}), 1);
i2 = find(strcmp(ordered_names, parts{2}), 1);
iactual = find(strcmp(ordered_names, actual), 1);
tf = ~isempty(i1) && ~isempty(i2) && ~isempty(iactual) ...
  && iactual >= min(i1, i2) && iactual <= max(i1, i2);

return
end

function parts = split_range_token(token)
%split_range_token - 軸名範囲を表す区切り文字を分離する
parts = {token};
separators = {':', '～', '~'};
for iseparator = 1:length(separators)
  if contains(token, separators{iseparator})
    values = strsplit(token, separators{iseparator});
    parts = cellfun(@strtrim, values, 'UniformOutput', false);
    return
  end
end

return
end

function [element_load, reflected, issues] = apply_record( ...
  element_load, row, idme, csv_row, com, weight_case, ...
  weight_type, issues)
%apply_record - 一つのセグメント入力を解析・位置・重量へ分離する
reflected = false;
fixed = cell2mat(row(8:19));
invalid_fixed = ~isfinite(fixed);
if any(invalid_fixed)
  fixed(invalid_fixed) = 0;
  issues = add_issue(issues, 'ElementLoadInvalidFixedForce', '', csv_row);
end

m0 = row{20};
if ~isnumeric(m0) || ~isscalar(m0) || ~isfinite(m0)
  m0 = 0;
end
quarter = cell2mat(row(21:24));
quarter(~isfinite(quarter)) = NaN;

analysis_case = tochar(row{1});
is_exey = weight_case == PRM.ELOAD_CASE_EXEY;
ilc = find(strcmp(com.loadcase.name, analysis_case), 1);
if is_exey && ~isempty(analysis_case)
  issues = add_issue(issues, 'ElementLoadExeyAnalysisCase', '', csv_row);
elseif ~isempty(analysis_case) && isempty(ilc)
  issues = add_issue(issues, 'ElementLoadUnknownLoadCase', '', csv_row);
elseif ~isempty(ilc)
  element_load.analysis_ar(idme, :, ilc) = ...
    element_load.analysis_ar(idme, :, ilc) + fixed;
  element_load.M0(idme, ilc) = element_load.M0(idme, ilc) + m0;
  record = struct('idme', idme, 'ilc', ilc, 'ar', fixed, ...
    'M0', m0, 'quarter', quarter, 'csv_row', csv_row);
  element_load.position(end + 1, 1) = record;
  reflected = true;
end

if weight_case > 0
  element_load.weight_ar(idme, :, weight_case, weight_type) = ...
    element_load.weight_ar(idme, :, weight_case, weight_type) + fixed;
  if weight_type == PRM.ELOAD_TYPE_FOUNDATION
    endpoint = [com.member.property.idnode1(idme), ...
      com.member.property.idnode2(idme)];
    if ~any(ismember(endpoint, com.support.idnode))
      issues = add_issue(issues, 'ElementLoadFoundationOffSupport', ...
        '', csv_row);
    end
  end
  reflected = true;
end

return
end

function issues = add_issue(issues, id, detail, csv_row)
%add_issue - 警告IDと詳細、元CSV行を集約用配列へ追加する
issue.id = id;
issue.detail = detail;
issue.row = csv_row;
issues(end + 1, 1) = issue;

return
end
