function [value, is_valid] = normalize_numeric_cell(value)
%normalize_numeric_cell - セル値を数値入力の2状態へ正規化する
%
%   [value, is_valid] = normalize_numeric_cell(value) は、数値列の
%   セル値を、数値 (入力あり) と NaN (空欄・未入力) の2状態へ正規化
%   する。数値として解釈できない入力は is_valid=false で返し、呼び
%   出し側がエラーとして読込を停止する。文字列の NaN・Inf は
%   readcell が数値の NaN・±Inf として返すため、有限でない数値も
%   解釈できない入力とする。data_block_class の D 列正規化と、形式
%   判定後に数値列を解釈する新入力アダプターが共用する。
%
%   入力引数:
%     value - readcell が返したセル値
%
%   出力引数:
%     value    - double スカラー
%     is_valid - 数値として解釈できたか（空欄・未入力は true）
is_valid = true;
if isnumeric(value) && isscalar(value) && isreal(value)
  if isfinite(value)
    value = double(value);
  else
    is_valid = false;
  end
elseif isempty(value) || (isscalar(value) && ismissing(value))
  value = NaN;
else
  is_valid = false;
end

return
end
