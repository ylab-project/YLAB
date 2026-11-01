function [nodal_force, issues] = ...
  parse_cantilever_force_block(cantilever_force, placements, com, issues)
%parse_cantilever_force_block - 片持梁荷重を取付節点へ縮約する
%
%   [nodal_force, issues] = parse_cantilever_force_block( ...
%     cantilever_force, placements, com, issues) は、配置から元端節点と
%   基準柱を検索し、回転・長さ・先端移動を使ってC・Qoを縮約する。
%
%   入力引数:
%     cantilever_force - 正規化した配置指定とC・Qo、重量分類の表
%     placements       - 正規化した片持梁配置の表
%     com              - 荷重割当の基準となる解析モデル
%     issues           - 入力値の検証で収集した警告
%
%   出力引数:
%     nodal_force - 取付節点へ縮約した6成分と重量分類の荷重表
%     issues      - 配置解決時の警告を含む入力警告

[placements, issues] = parse_placements(placements, com, issues);
placement_keys = {placements.key};
n = height(cantilever_force);
idnode = zeros(n, 1);
f = zeros(n, 6);
for ir = 1:n
  label = cantilever_force.block_name{ir};
  ib = cantilever_force.iblock(ir);
  csv_line = cantilever_force.csv_row(ir);
  ip = find(strcmp(placement_keys, ...
    strjoin(cantilever_force.selector(ir, :), '|')), 1);
  if isempty(ip)
    issues = add_input_issue(issues, 'CantileverLoadUnresolved', ...
      '配置なし', label, ib, csv_line, ...
      strjoin(cantilever_force.selector(ir, :), '/'), 1, 0, 1, '');
    continue
  end
  placement = placements(ip);
  if ~isempty(placement.reason)
    issues = add_input_issue(issues, 'CantileverLoadUnresolved', ...
      placement.reason, label, ib, csv_line, ...
      strjoin(cantilever_force.selector(ir, :), '/'), 1, 0, 1, '');
    continue
  end
  idnode(ir) = placement.idnode;
  f(ir, :) = calc_cantilever_nodal_force(placement.r, ...
    cantilever_force.c_base(ir), cantilever_force.c_tip(ir), ...
    cantilever_force.q_base(ir), cantilever_force.q_tip(ir));
  if cantilever_force.wtype(ir) == PRM.WTYPE_FOUNDATION
    issues = check_foundation_support(placement.idnode, com, label, ib, ...
      csv_line, strjoin(cantilever_force.selector(ir, :), '/'), issues);
  end
end
is_cantilever = true(n, 1);
nodal_force = removevars(cantilever_force, {'selector', 'c_base', ...
  'c_tip', 'q_base', 'q_tip'});
nodal_force = addvars(nodal_force, idnode, 'Before', 1);
nodal_force = addvars(nodal_force, f, 'After', 'ilc');
nodal_force = addvars(nodal_force, is_cantilever, 'After', 'wtype');
nodal_force = nodal_force(idnode > 0, :);

return
end


function [placements, issues] = parse_placements(placement_input, ...
  com, issues)
%parse_placements - 片持梁配置の作用節点と幾何を解決する
%
%   [placements, issues] = parse_placements(placement_input, com, ...
%     issues) は、各配置を解決し、重複キーを参照する荷重を
%   未反映にする。
%
%   入力引数:
%     placement_input - 正規化した配置指定と幾何入力のテーブル
%     com             - 取付節点と柱回転を持つ解析モデル
%     issues          - 収集済みの入力警告
%
%   出力引数:
%     placements - 作用節点、元端から先端へのベクトルと解決不能理由
%     issues     - 重複キーの警告を追加した入力警告

placements = struct('key', {}, 'idnode', {}, 'r', {}, ...
  'reason', {}, 'iblock', {}, 'csv_row', {});
for ir = 1:height(placement_input)
  placement = resolve_placement(placement_input(ir, :), com);
  placement.iblock = placement_input.iblock(ir);
  placement.csv_row = placement_input.csv_row(ir);
  placements(end + 1, 1) = placement; %#ok<AGROW>
end

% 同一キーの重複は幾何を一意に解決できないため配置を警告し、
% そのキーを参照する荷重行を未反映にする
keys = {placements.key};
for k = 1:length(placements)
  if nnz(strcmp(keys, placements(k).key)) > 1
    placements(k).reason = '配置キー重複';
    issues = add_input_issue(issues, 'CantileverPlacementDuplicated', ...
      '', '片持梁配置', placements(k).iblock, placements(k).csv_row, ...
      placements(k).key, 1, 0, 1, '');
  end
end

return
end


function placement = resolve_placement(row, com)
%resolve_placement - 片持梁の取付節点と先端位置を解決する
%
%   placement = resolve_placement(row, com)
%   は、配置指定から元端節点と基準柱を検索し、柱の回転と先端移動を
%   考慮した元端から先端へのベクトルを返す。
%
%   入力引数:
%     row - 配置指定、長さ、水平・鉛直の先端位置を持つ入力行
%     com - 節点と柱の方向を持つ基準解析モデル
%
%   出力引数:
%     placement - 配置キー、元端節点番号と元端から先端のベクトル
%                 基準柱は元端を柱頭とする柱を優先する。
%                 reasonが空でなければ配置を解決できていない。

names = row.selector;
placement.key = strjoin(names, '|');
placement.idnode = 0;
placement.r = zeros(1, 3);
placement.reason = '';

% 取付節点（元端節点）
idnode = find_idnode_from_names(names{1}, names{2}, names{3}, com);
if idnode == 0
  placement.reason = '取付節点なし';
  return
end
placement.idnode = idnode;

% 基準方向
switch names{4}
  case 'X+'
    base_dir = [1, 0, 0];
  case 'X-'
    base_dir = [-1, 0, 0];
  case 'Y+'
    base_dir = [0, 1, 0];
  case 'Y-'
    base_dir = [0, -1, 0];
  otherwise
    placement.reason = '規定外の方向';
    return
end

% 基準柱（元端節点を柱頭とする直下の柱を優先する）
member_column = com.member.column;
ic = find(member_column.idnode2 == idnode, 1);
if isempty(ic)
  ic = find(member_column.idnode1 == idnode, 1);
end
if isempty(ic)
  placement.reason = '基準柱なし';
  return
end
angle = deg2rad(member_column.angle(ic));
rot = [cos(angle), -sin(angle), 0; sin(angle), cos(angle), 0; 0, 0, 1];
e1 = (rot * base_dir.').';
e2 = cross([0, 0, 1], e1);

% 元端－先端ベクトル（長さは通り心基点の跳ね出し長さ）
len = row.len;
tip_lr = row.tip_lr;
tip_ud = row.tip_ud;
if ~(len > 0)
  placement.reason = '長さ0以下';
  return
end
placement.r = len * e1 + tip_lr * e2 + tip_ud * [0, 0, 1];

return
end
