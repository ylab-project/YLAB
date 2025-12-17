function throw_err(cat, id, varargin)
% THROW_ERR エラーを投げるためのユーティリティ関数
%
%   THROW_ERR(CAT, ID, VARARGIN) は指定されたカテゴリとIDでエラーを投げます。
%   最初にoptions構造体（.errfileフィールドを持つ）を渡すと、
%   そのファイルにエラーメッセージを書き出すようになります。
%
%   入力引数:
%       CAT - エラーのカテゴリ（例: 'Input', 'File'など）
%       ID  - エラーの識別子（例: 'InvalidSize', 'FileNotFound'など）
%       VARARGIN - エラーメッセージに埋め込む変数（可変長引数）
%
%   例:
%       throw_err('Input', 'InvalidSize', varName, expected, options)
%       throw_err('Input', 'InvalidSize', varName, expected) % 2回目以降はoptions省略可

persistent errfile
persistent msgtable

% catとidが空、かつvararginが1つだけ、かつそれが文字列の場合のみエラーファイル名を登録して即終了
if isempty(cat) && isempty(id) && ischar(varargin{1})
  errfile = varargin{1};
  fid = fopen(errfile, 'w');
  if fid ~= -1
    fclose(fid);
  end
  msgtable = error_messages_table();
  return;
end
msg = error_messages(id, msgtable, varargin);
fullID = sprintf('YLAB:%s:%s', cat, id);

% errfileが登録されていればファイルに書き出し
if ~isempty(errfile)
  write_error_to_file(errfile, fullID, msg);
end

throwAsCaller(MException(fullID, msg));
end

function write_error_to_file(errfile, fullID, msg)
% WRITE_ERROR_TO_FILE 指定ファイルにエラーメッセージを書き出す
% timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
fid = fopen(errfile, 'a');
if fid ~= -1
  fprintf(fid, '[%s] %s \n', fullID, msg);
  fclose(fid);
end
end

function msg = error_messages(id, msgtable, argin)
% ERROR_MESSAGES エラーメッセージを管理する関数
%
%   MSG = ERROR_MESSAGES(ID, VARARGIN) は指定されたIDに対応するエラーメッセージを返します。
%   エラーメッセージはerror_messages.csvファイルから読み込まれます。
%
%   入力引数:
%       ID - エラーメッセージのID
%       VARARGIN - エラーメッセージに埋め込む変数
%
%   例:
%       msg = error_messages('EmptySectionList', 'limit_jbs_section')

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
