function history = ensure_lsr_history_info(history)
%ensure_lsr_history_info - LSR履歴の付加記録スキーマを保証する
%
%   history = ensure_lsr_history_info(history) は、構造体配列またはcell
%   配列を含むLSR履歴を構造体配列へ統一し、旧lsr_timingを
%   history.infoへ移行する。不足する反復列と行はNaNで補完する。
%
%   入力引数:
%     history - LSR履歴の構造体、構造体配列、またはcell配列
%
%   出力引数:
%     history - 付加記録スキーマを保証した構造体配列

history_size = size(history);
if iscell(history) || numel(history) > 1
  if iscell(history)
    history_cells = history(:);
  else
    history_cells = num2cell(history(:));
  end
  is_valid = false(size(history_cells));
  for ihistory = 1:numel(history_cells)
    element = history_cells{ihistory};
    if isempty(element)
      continue
    end
    if ~isstruct(element) || numel(element) ~= 1
      error('ensure_lsr_history_info:InvalidHistory', ...
        'History contains an invalid element.');
    end
    history_cells{ihistory} = ensure_lsr_history_info(element);
    is_valid(ihistory) = true;
  end
  if ~any(is_valid)
    error('ensure_lsr_history_info:EmptyHistory', ...
      'History does not contain a valid element.');
  end
  template = history_cells{find(is_valid, 1)};
  empty_history = template;
  names = fieldnames(empty_history);
  for id = 1:numel(names)
    empty_history.(names{id}) = [];
  end
  empty_history.info = struct;
  empty_history = ensure_lsr_history_info(empty_history);
  for ihistory = find(~is_valid)'
    history_cells{ihistory} = empty_history;
  end
  history = reshape([history_cells{:}], history_size);
  return
end

if ~isstruct(history)
  error('ensure_lsr_history_info:InvalidHistory', ...
    'History must be a structure or cell array.');
end
nrow = size(history.iter, 1);
if isfield(history, 'lsr_timing')
  if ~isfield(history, 'info')
    history.info = struct;
  end
  if ~isfield(history.info, 'lsr')
    history.info.lsr = struct;
  end
  history.info.lsr.timing = history.lsr_timing;
  history = rmfield(history, 'lsr_timing');
end
if ~isfield(history, 'info')
  history.info = struct;
end

schema = lsr_history_info_schema();
for id = 1:numel(schema)
  method = schema(id).method;
  category = schema(id).category;
  if ~isfield(history.info, method)
    history.info.(method) = struct;
  end
  if ~isfield(history.info.(method), category)
    history.info.(method).(category) = struct;
  end
  for jd = 1:numel(schema(id).fields)
    field = schema(id).fields{jd};
    if isfield(history.info.(method).(category), field)
      values = history.info.(method).(category).(field);
      values = values(:);
      values(end+1:nrow, 1) = nan;
      values = values(1:nrow, 1);
    else
      values = nan(nrow, 1);
    end
    history.info.(method).(category).(field) = values;
  end
end

return
end