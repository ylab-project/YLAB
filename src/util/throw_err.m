function throw_err(cat, id, varargin)
%throw_err - エラーを投げるためのユーティリティ関数
%
%   throw_err(cat, id, varargin) は指定されたカテゴリとIDでエラーを投げます。
%   エラーはMATLABのMExceptionを使用して発生され、処理は停止します。
%
%   入力引数:
%     cat - エラーのカテゴリ（例: 'Input', 'SectionList'など）
%     id  - エラーの識別子（例: 'InvalidSize', 'EmptyList'など）
%     varargin - メッセージに埋め込む変数（可変長引数）
%
%   例:
%     throw_err('IO', 'FileNotFound', label, filepath)
%
%   参考:
%     throw_warn, throw_msg_impl

throw_msg_impl('error', cat, id, varargin{:});

return
end
