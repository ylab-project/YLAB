function num_workers = resolve_num_workers(spec, default_num_workers)
%resolve_num_workers - numworkers引数の値をワーカー数の整数へ換算する
%
%   num_workers = resolve_num_workers(spec, default_num_workers) は、
%   実行時引数 'numworkers' の値 spec を並列プールのワーカー数に
%   換算する。末尾が '%' の文字列は既定ワーカー数 default_num_workers
%   に対する割合とし、それ以外は正の整数として読む。
%
%   入力引数:
%     spec                - 'numworkers' の値 (double, char または string)
%     default_num_workers - 既定ワーカー数（並列プロファイルの NumWorkers）
%
%   出力引数:
%     num_workers - ワーカー数 (正の整数)
%
%   備考:
%     - 割合は max(1, floor(N/100 × 既定数)) で換算し、100%超も可
%     - 0以下、非整数、数値に読めない値は throw_err で
%       YLAB:Input:InvalidNumWorkers エラーを発行

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
if is_percent
  % 'N%' は既定ワーカー数に対する割合。切り捨てで最低1ワーカーにする
  number = max(1, floor(number / 100 * default_num_workers));
end
num_workers = number;

return
end
