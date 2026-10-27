function [num_workers, num_cores] = resolve_num_workers(spec)
%resolve_num_workers - numworkers引数をワーカー数の整数へ換算する
%
%   [num_workers, num_cores] = resolve_num_workers(spec) は、
%   実行時引数をワーカー数に換算する。末尾が '%' の文字列は
%   PコアとEコアを含む有効物理コア数に対する割合とする。
%
%   入力引数:
%     spec - 'numworkers' の値 (double, char または string)
%
%   出力引数:
%     num_workers - ワーカー数 (正の整数)
%     num_cores   - 有効物理コア数 (正の整数)
%
%   備考:
%     - 割合は小数点以下切り捨て、最低1ワーカーとし、100%超も可
%     - 割合指定時または第2出力の要求時にコア数を1回取得する
%     - 不正な指定は YLAB:Input:InvalidNumWorkers、コア数の取得に
%       失敗した場合は YLAB:Env:ProcessorInfoFailed で停止する

spec = convertStringsToChars(spec);
is_percent = false;
number = spec;
if ischar(spec)
  % 末尾の '%' を除いて数値化する
  is_percent = endsWith(spec, '%');
  number = str2double(spec(1:end-is_percent));
end
if ~(isscalar(number) && isfinite(number) && number > 0 ...
    && (is_percent || number == floor(number)))
  throw_err('Input', 'InvalidNumWorkers', spec);
end
if is_percent || nargout >= 2
  % 配布先でも使えるWindows標準のPowerShellで全CPU分を合計する。
  % 論理プロセッサ数と、無効にされた物理コアは分母に含めない。
  cmd = ['powershell.exe -NoProfile -NonInteractive -Command "', ...
    '(Get-CimInstance Win32_Processor -ErrorAction Stop | ', ...
    'Measure-Object NumberOfEnabledCore -Sum).Sum"'];
  [status, output] = system(cmd);
  num_cores = str2double(strtrim(output));
  if status ~= 0 || ~(isscalar(num_cores) && isfinite(num_cores) ...
      && num_cores > 0 && num_cores == floor(num_cores))
    throw_err('Env', 'ProcessorInfoFailed', strtrim(output));
  end
end
if is_percent
  number = max(1, floor(number / 100 * num_cores));
end
num_workers = number;

return
end
