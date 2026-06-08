function r = ceil_ratio(ratio)
%ceil_ratio - 検定比を小数2桁へ切り上げる（SS7 互換の表示丸め）
%
%   r = ceil_ratio(ratio) は検定比を小数2桁で切り上げ（ceil）した値を
%   返す。検定比一覧・断面算定表（柱・梁）の表示丸め規則を統一する。
%   NG（1.0 超）の '*' 付与は表示側で行う。
%
%   入力引数:
%     ratio - 検定比（非負）
%
%   出力引数:
%     r - 小数2桁へ切り上げた検定比

r = ceil(ratio * 100) / 100;

return
end
