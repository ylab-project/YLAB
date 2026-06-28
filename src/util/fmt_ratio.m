function s = fmt_ratio(ratio, mark_ng)
%fmt_ratio - 検定比を小数2桁切り上げで文字列化する
%
%   s = fmt_ratio(ratio, mark_ng) は検定比 ratio を SS7 互換の
%   小数2桁切り上げで文字列化する。mark_ng が true で、丸め後の
%   値が 1.0 を超える場合は末尾に '*' を付す。
%
%   入力引数:
%     ratio   - 検定比
%     mark_ng - NG時に '*' を付けるかどうか（省略時 true）
%
%   出力引数:
%     s - 表示用文字列

if nargin < 2
  mark_ng = true;
end

r = ceil_ratio(ratio);
if mark_ng && r > 1.0
  s = sprintf('%.2f*', r);
else
  s = sprintf('%.2f', r);
end

return
end