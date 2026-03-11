function throw_warn(cat, id, varargin)
%throw_warn - 警告を出すためのユーティリティ関数
%
%   throw_warn(cat, id, varargin) は指定されたカテゴリとIDで警告を出します。
%   警告はMATLABのwarning関数を使用して表示され、処理は継続されます。
%
%   入力引数:
%     cat - 警告のカテゴリ（例: 'Input', 'SectionList'など）
%     id  - 警告の識別子（例: 'EmptyList', 'TypeMismatch'など）
%     varargin - メッセージに埋め込む変数（可変長引数）
%
%   例:
%     throw_warn('List', 'EmptyAfterFilter', listname)
%
%   参考:
%     throw_err, throw_msg_impl

throw_msg_impl('warning', cat, id, varargin{:});

return
end
