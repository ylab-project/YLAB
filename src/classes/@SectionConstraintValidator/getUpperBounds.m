function ub = getUpperBounds(obj, idsList)
%getUpperBounds 設計変数の上限値を取得
%   ub = getUpperBounds(obj, idsList) は、指定された断面リストIDに
%   対する各変数の上限値を計算します。各変数タイプ（H, B, tw, tf, 
%   D, t等）の最大値を計算し、該当しない変数にはNaNを設定します。
%
%   入力引数:
%     idsList - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     ub - 上限値ベクトル [1×nxvar]
%          該当しない変数はNaN
%
%   例:
%     ub = validator.getUpperBounds(1);
%
%   参考:
%     getLowerBounds, computeBounds

% computeBoundsメソッドを使用して上限値を計算
ub = obj.computeBounds(idsList, 'upper');

return
end