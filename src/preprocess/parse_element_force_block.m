function [element_force, issues] = ...
  parse_element_force_block(element_force, com, issues)
%parse_element_force_block - 線材荷重の入力行を解析部材へ対応付ける
%
%   [element_force, issues] = parse_element_force_block( ...
%     element_force, com, issues) は、配置指定と継続順から部材列への
%   対応を確定する。値は再配分せず、行と区間を順に対応させる。
%
%   入力引数:
%     element_force - 正規化した未解決の線材荷重テーブル
%     com           - 荷重割当の基準となる解析モデル
%     issues        - 入力値の検証で収集した警告
%
%   出力引数:
%     element_force - 作用先を全体部材番号で持つ荷重テーブル
%     issues        - 作用先と反映件数を含めた警告

idme = zeros(height(element_force), 1);
ir = 1;
while ir <= height(element_force)
  group = ir;
  while element_force.is_continued(group(end))
    group(end + 1) = group(end) + 1; %#ok<AGROW>
  end
  label = element_force.block_name{ir};
  ib = element_force.iblock(ir);
  csv_head = element_force.csv_row(ir);
  def = element_force_layout(label);
  ntarget = def.comp_col - def.target_col;
  selector = element_force.selector(ir, 1:ntarget);
  [chain, issues] = resolve_group_target(selector, def.kind, com, ...
    csv_head, issues, label, ib);
  if isempty(chain)
    ir = group(end) + 1;
    continue
  end
  napply = min(length(chain), length(group));
  input_value = sprintf('入力行%d/要素%d', length(group), length(chain));
  if length(chain) > length(group)
    issues = add_input_issue(issues, 'ElementLoadContRowMissing', ...
      '', label, ib, csv_head, input_value, 1, napply, ...
      length(chain) - napply, '');
  elseif length(chain) < length(group)
    issues = add_input_issue(issues, 'ElementLoadContRowExtra', ...
      '', label, ib, csv_head, input_value, 1, napply, ...
      length(group) - napply, '');
  end
  idme(group(1:napply)) = chain(1:napply);
  if element_force.wtype(ir) == PRM.WTYPE_FOUNDATION
    applied = chain(1:napply);
    property = com.member.property;
    endpoint = [property.idnode1(applied), property.idnode2(applied)];
    issues = check_foundation_support(endpoint, com, label, ib, ...
      csv_head, mat2str(applied), issues);
  end
  ir = group(end) + 1;
end

% 解決済みの表には作用先と荷重の正本だけを残す。
element_force = removevars(element_force, {'selector', 'is_continued'});
element_force = addvars(element_force, idme, 'Before', 1);
element_force = element_force(idme > 0, :);

return
end

function [chain, issues] = resolve_group_target(names, ...
  kind, com, csv_row, issues, block_name, iblock)
%resolve_group_target - 配置指定を順序付きの部材列へ対応付ける
%
%   [chain, issues] = resolve_group_target(names, ...
%   kind, com, csv_row, issues, block_name, iblock)
%   は、梁・柱の接続をたどって区間の部材番号を返し、
%   対象がない場合と順序が一意でない場合を警告へ記録する。
%
%   入力引数:
%     names - 正規化した階・方向・軸の配置指定
%     kind - girderまたはcolumn
%     com - 荷重割当の基準となる解析モデル
%     csv_row - 元CSV行番号
%     issues - 収集済みの入力警告
%     block_name - 入力ブロック名
%     iblock - 同名ブロックの出現番号
%
%   出力引数:
%     chain - 入力区間の順序に並ぶ部材番号。未解決は空
%     issues - 作用先の検証結果を追加した入力警告

input_value = strjoin(names, '/');
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
