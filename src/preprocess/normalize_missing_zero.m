function values = normalize_missing_zero(values)
%normalize_missing_zero - 空欄由来のNaNを数値0へ置き換える
%
%   values = normalize_missing_zero(values) は、数値セルの正規化で空欄
%   がNaNになった要素を0にする。部材端応力、節点荷重の6成分および
%   片持梁のC・Qoは空欄を数値0として扱う（内部設計3章）。
%
%   入力引数:
%     values - 数値セル正規化後の値（スカラーまたは配列）
%
%   出力引数:
%     values - 空欄由来のNaNを0にした値
values(isnan(values)) = 0;

return
end
