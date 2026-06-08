function s = fmt_ceil_abs(x, ndec)
%fmt_ceil_abs - 絶対値方向に ndec 桁切り上げて固定小数文字列化
%
%   s = fmt_ceil_abs(x, ndec) は ceil_abs で x を絶対値が大きくなる
%   向きに小数 ndec 桁へ切り上げ（表示桁で 0 になる微小値の 0 丸めを
%   含む）、ndec 桁の固定小数点で文字列化する。SS7 出力編 A.9 に従う
%   応力・断面諸量・座屈諸元の表示に使う。
%
%   入力引数:
%     x    - 表示対象の数値（スカラー）
%     ndec - 小数桁数（0:整数, 1:小数1桁, ...）
%
%   出力引数:
%     s - ndec 桁固定小数の文字列

s = sprintf('%.*f', ndec, ceil_abs(x, ndec));

return
end
