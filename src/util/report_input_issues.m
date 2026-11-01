function issues = report_input_issues(issues, varargin)
%report_input_issues - 入力警告を種別ごとに集約して通知する
%
%   issues = report_input_issues(issues, varargin) は、
%   解決済み荷重表からタイプの2警告の適用件数を確定し、
%   入力位置、件数とフォールバック先を警告IDごとにまとめて通知する。
%
%   入力引数:
%     issues   - add_input_issueで収集した警告レコード構造体配列
%     varargin - 解決済みの線材・節点荷重表（0個以上）。
%                block_name、iblock、csv_row列を使う。
%                表がなければタイプの2警告は未反映として通知する。
%
%   出力引数:
%     issues - 荷重の割当結果に基づく件数を持つ警告レコード
if isempty(issues)
  return
end

ids = {issues.id};
% read_weight_headのタイプの2警告だけを割当結果から確定する。
% 未解釈の区分は行を保持しないため、記録済みの未反映件数を維持する。
% 同じ入力位置の荷重が残れば適用とし、ilc=0の地震用の重量も含める。
for k = find(ismember(ids, {'ElementLoadUnknownType', ...
    'ElementLoadLlUnusualType'}))
  issues(k).applied_count = 0;
  for j = 1:numel(varargin)
    force = varargin{j};
    if any(strcmp(force.block_name, issues(k).block_name) & ...
        force.iblock == issues(k).iblock & force.csv_row == issues(k).row)
      issues(k).applied_count = issues(k).input_count;
      break
    end
  end
  issues(k).unapplied_count = ...
    issues(k).input_count - issues(k).applied_count;
end
unique_ids = unique(ids, 'stable');
for iid = 1:length(unique_ids)
  selected = issues(strcmp(ids, unique_ids{iid}));
  rows = unique([selected.row]);
  blocks = arrayfun(@(issue) sprintf('%s[%d]', issue.block_name, ...
    issue.iblock), selected, 'UniformOutput', false);
  blocks = unique(blocks, 'stable');
  summary = sprintf(['入力=%d, 適用=%d, 未反映=%d, ブロック=%s, ' ...
    'CSV行=%s'], sum([selected.input_count]), ...
    sum([selected.applied_count]), sum([selected.unapplied_count]), ...
    strjoin(blocks, '/'), mat2str(rows));

  input_values = unique_nonempty({selected.input_value});
  if ~isempty(input_values)
    values = strjoin(input_values, '/');
    summary = sprintf('%s, 入力値=%s', summary, values);
  end
  details = unique_nonempty({selected.detail});
  if ~isempty(details)
    summary = sprintf('%s, 詳細=%s', summary, strjoin(details, '/'));
  end
  fallbacks = unique_nonempty({selected.fallback});
  if ~isempty(fallbacks)
    summary = sprintf('%s, フォールバック=%s', summary, ...
      strjoin(fallbacks, '/'));
  end
  throw_warn('Input', unique_ids{iid}, summary);
end

return
end


function values = unique_nonempty(values)
%unique_nonempty - 空文字を除いた一意な文字列を出現順で返す
%
%   values = unique_nonempty(values) は、警告の入力値・詳細から
%   空文字と重複を除き、最初に現れた順の文字列を返す。
%
%   入力引数:
%     values - 警告に記録した文字列のセル配列
%
%   出力引数:
%     values - 空文字と重複を除いた文字列のセル配列
values = values(~cellfun(@isempty, values));
values = unique(values, 'stable');

return
end
