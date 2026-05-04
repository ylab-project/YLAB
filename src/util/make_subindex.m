function [sub, sub_raw] = make_subindex(v, expand_id)
%make_subindex - 入力CSV添字から内部用/出力用のペアを生成
%
%   [sub, sub_raw] = make_subindex(v, expand_id) は、入力CSVの添字値
%   v から、内部参照用 sub と出力用 sub_raw を返す。sub_raw は入力値を
%   そのまま保持し、sub は '-' のとき expand_id（梁=層番号、柱=
%   階番号）の文字列に置換、それ以外は v を返す。
%
%   入力引数:
%     v         - 入力CSVの添字値（'R', '-', 数値等）
%     expand_id - '-' のとき展開する番号
%
%   出力引数:
%     sub     - 内部参照用添字（'-' を expand_id 文字列に置換）
%     sub_raw - 出力用添字（入力値をそのまま保持）

v = tochar(v);
sub_raw = v;
if strcmp(v, '-')
  sub = num2str(expand_id);
else
  sub = v;
end

end

