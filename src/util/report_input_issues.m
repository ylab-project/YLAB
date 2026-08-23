function report_input_issues(issues)
%report_input_issues - 入力警告を種別ごとに集約して通知する
%
%   report_input_issues(issues) は、収集した入力警告を警告IDごとに
%   集約し、入力位置、入力値、入力・適用・未反映件数および
%   フォールバック先を一つのメッセージで通知する。
%
%   入力引数:
%     issues - add_input_issueで収集した警告レコード構造体配列
if isempty(issues)
  return
end

ids = {issues.id};
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
values = values(~cellfun(@isempty, values));
values = unique(values, 'stable');

return
end