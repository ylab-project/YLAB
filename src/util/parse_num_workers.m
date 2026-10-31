function [number, is_percent, is_valid] = parse_num_workers(spec)
%parse_num_workers - ワーカー数指定の書式を解釈する
%
%   [number, is_percent, is_valid] = parse_num_workers(spec) は、
%   正の整数または正の割合を読み取り、マシン情報を取得せずに返す。
%   不正入力の通知方法はGUIと実行時の呼出し側が決める。
%
%   入力引数:
%     spec - ワーカー数の指定 (double, char または string)
%
%   出力引数:
%     number     - 入力された数値（is_validがfalseなら使用しない）
%     is_percent - 割合指定ならtrue
%     is_valid   - 正の整数または正の割合ならtrue

spec = convertStringsToChars(spec);
is_percent = false;
number = spec;
if ischar(spec)
  is_percent = endsWith(spec, '%');
  number = str2double(spec(1:end-is_percent));
end
is_valid = isnumeric(number) && isreal(number) && isscalar(number) ...
  && isfinite(number) && number > 0 ...
  && (is_percent || number == floor(number));

return
end
