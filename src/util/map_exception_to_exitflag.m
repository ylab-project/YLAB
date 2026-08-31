function exitflag = map_exception_to_exitflag(ME)
%map_exception_to_exitflag - 例外に対応する終了状態を返す
%
%   exitflag = map_exception_to_exitflag(ME) は、例外識別子の
%   エラーIDに対応する終了状態を返す。未登録の例外は内部エラーとして
%   扱う。
%
%   入力引数:
%     ME - 例外 (MException)
%
%   出力引数:
%     exitflag - 終了状態

% Ctrl+C割り込み（MATLAB:interrupt）
if strcmp(ME.identifier, 'MATLAB:interrupt')
  exitflag = PRM.EXITFLAG_USER_STOP;
  return
end
parts = split(ME.identifier, ':');
if numel(parts) >= 3
  id = parts{3};
else
  exitflag = PRM.EXITFLAG_INTERNAL_ERROR;
  return
end
tbl = error_messages_table();
idx = find(strcmp(tbl.id, id), 1);
if ~isempty(idx)
  exitflag = tbl.exitflag(idx);
else
  exitflag = PRM.EXITFLAG_INTERNAL_ERROR;
end

return
end
