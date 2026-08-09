function subindex = make_subindex(value)
%make_subindex - 入力CSVの添字を内部表現へ正規化する
%
%   subindex = make_subindex(value) は、入力CSVの添字 value を
%   charへ変換する。添字省略記号'-'と欠損値は空のcharを返す。
%
%   入力引数:
%     value - 入力CSVの添字値
%
%   出力引数:
%     subindex - 正規化した添字

subindex = tochar(value);
if strcmp(subindex, '-')
  subindex = '';
end

return
end
