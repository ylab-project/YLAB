function throw_msg_impl(severity, cat, id, varargin)
%throw_msg_impl - エラー/警告の共通処理（内部関数）

persistent errfile
persistent msgtable

% 初期化処理: catとidが空、かつvararginが文字列の場合
if isempty(cat) && isempty(id) && ~isempty(varargin) && ischar(varargin{1})
  errfile = varargin{1};
  fid = fopen(errfile, 'w');
  if fid ~= -1
    fclose(fid);
  end
  msgtable = error_messages_table();
  return;
end

% メッセージ取得
msg = get_message(id, msgtable, varargin);
fullID = sprintf('YLAB:%s:%s', cat, id);

% ファイル出力（登録されている場合）
if ~isempty(errfile)
  write_to_file(errfile, severity, fullID, msg);
end

% severityに応じてエラーまたは警告を発行
switch severity
  case 'error'
    throwAsCaller(MException(fullID, msg));
  case 'warning'
    warning(fullID, '%s', msg);
  otherwise
    error('throw_msg_impl:InvalidSeverity', ...
      'severity must be ''error'' or ''warning''');
end

return
end

function write_to_file(errfile, severity, fullID, msg)
%write_to_file - ファイルにメッセージを書き出す
fid = fopen(errfile, 'a');
if fid ~= -1
  fprintf(fid, '[%s][%s] %s\n', upper(severity), fullID, msg);
  fclose(fid);
end

return
end

function msg = get_message(id, msgtable, argin)
%get_message - メッセージテーブルからメッセージを取得

% 指定されたIDに対応するメッセージを検索
idx = find(strcmp(msgtable.id, id), 1);
if isempty(idx)
  idx = find(strcmp(msgtable.id, 'UnknownError'), 1);
end

% メッセージ検索
msgfmt = msgtable.message{idx};

% 可変サフィックス ([[...]]) の処理
has_arg = ~isempty(argin);
opt_pattern = '\[\[(.*?)\]\]';
if has_arg
  msgfmt = regexprep(msgfmt, opt_pattern, '（$1）');
else
  msgfmt = regexprep(msgfmt, opt_pattern, '');
end

% 数値/論理引数は文字列に変換
if has_arg
  for i = 1:numel(argin)
    if isnumeric(argin{i}) || islogical(argin{i})
      argin{i} = strtrim(num2str(argin{i}(:).'));
    end
  end
end

% フォーマット指定子が含まれている場合のみ sprintf
if has_arg && contains(msgfmt, '%')
  msg = sprintf(msgfmt, argin{:});
else
  msg = msgfmt;
end

return
end
