function [nodal_force, issues] = parse_nodal_force_block(nodal_force, ...
  com, issues)
%parse_nodal_force_block - 正規化した節点荷重の作用先を解決する
%
%   [nodal_force, issues] = parse_nodal_force_block( ...
%     nodal_force, com, issues) は、配置指定を代表節点へ対応付ける。
%   作用先がない行は反映せず、元CSV行と未反映件数を警告へ記録する。
%
%   入力引数:
%     nodal_force - 正規化した未解決の節点荷重テーブル
%     com         - 荷重割当の基準となる解析モデル
%     issues      - 入力値の検証で収集した警告
%
%   出力引数:
%     nodal_force - 作用先を節点番号で持つ荷重テーブル
%     issues      - 作用先と反映件数を含めた警告

idnode = zeros(height(nodal_force), 1);
for ir = 1:height(nodal_force)
  label = nodal_force.block_name{ir};
  ib = nodal_force.iblock(ir);
  csv_line = nodal_force.csv_row(ir);
  [idnode(ir), issues] = resolve_node_target(nodal_force.selector(ir, ...
    :), com, csv_line, issues, label, ib);
  if idnode(ir) == 0
    continue
  end
  if nodal_force.wtype(ir) == PRM.WTYPE_FOUNDATION
    issues = check_foundation_support(idnode(ir), com, label, ib, ...
      csv_line, nodal_force.input_value{ir}, issues);
  end
end
nodal_force = removevars(nodal_force, {'selector', 'input_value'});
nodal_force = addvars(nodal_force, idnode, 'Before', 1);
nodal_force = nodal_force(idnode > 0, :);

return
end

function [idnode, issues] = resolve_node_target(names, ...
  com, csv_row, issues, block_name, iblock)
%resolve_node_target - 層・X軸・Y軸の指定から対象節点を解決する
%
%   [idnode, issues] = resolve_node_target(names, com, csv_row, ...
%     issues, block_name, iblock) は、正規化済みの配置指定を検索する。
%
%   入力引数:
%     names      - 層・X軸・Y軸の文字列 {1×3}
%     com        - 節点と基準線の対応を持つ解析モデル
%     csv_row    - 元CSV行番号
%     issues     - 収集済みの入力警告
%     block_name - 入力ブロック名
%     iblock     - 同名ブロックの出現番号
%
%   出力引数:
%     idnode - 作用先節点番号。未解決は0
%     issues - 作用先の警告を追加した入力警告

input_value = strjoin(names, '/');
idnode = find_idnode_from_names(names{1}, names{2}, names{3}, com);
if idnode == 0
  issues = add_input_issue(issues, 'ElementLoadNodeNotFound', '', ...
    block_name, iblock, csv_row, input_value, 1, 0, 1, '');
  return
end

return
end
