function text = format_subindex(subindex)
%format_subindex - 添字をSS7出力の表記へ変換する
%
%   text = format_subindex(subindex) は、内部表現の添字を
%   SS7出力の添字欄の表記へ変換する。添字なしの空charは
%   省略記号'-'として出力する。make_subindexの逆変換である。
%
%   入力引数:
%     subindex - 内部表現の添字
%
%   出力引数:
%     text - SS7出力の添字表記

text = subindex;
if isempty(text)
  text = '-';
end

return
end
