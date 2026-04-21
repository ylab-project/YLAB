function tf = is_all_token(s)
%is_all_token - 範囲指定の「全/ALL」リテラル判定
%
%   tf = is_all_token(s) は、文字列 s が範囲指定の全範囲リテラル
%   （'全' または 'ALL'/'all'、大小文字無視）であれば true を返す。
%
%   入力引数:
%     s - 判定対象の文字列
%
%   出力引数:
%     tf - 全範囲リテラルなら true、それ以外は false (logical)
tf = strcmp(s, '全') || strcmpi(s, 'ALL');
return
end
