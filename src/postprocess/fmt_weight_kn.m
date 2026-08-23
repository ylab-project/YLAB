function text = fmt_weight_kn(value, blank_threshold)
%fmt_weight_kn - N単位の重量をkNの小数1桁表示へ切り上げる
%
%   text = fmt_weight_kn(value, blank_threshold) は、N単位の重量をkNへ
%   換算し、表示境界の浮動小数誤差を除いたうえで絶対値方向に小数1桁
%   へ切り上げる（SS7出力編A.9）。kN換算値の絶対値がblank_threshold
%   未満の欄は空欄にする。全欄を常に表示する帳票は0を渡す。
%
%   入力引数:
%     value           - N単位の重量
%     blank_threshold - 空欄にするkN単位の下限
%
%   出力引数:
%     text - 小数1桁の固定小数文字列。下限未満は空文字
value_kn = value * 1e-3;
if abs(value_kn) < blank_threshold
  text = '';
  return
end
scaled = round(abs(value_kn) * 10, 9);
text = sprintf('%.1f', sign(value_kn) * ceil(scaled) / 10);

return
end
