function lb = getLowerBounds(obj, idsList)
%getLowerBounds 設計変数の下限値を取得
%   lb = getLowerBounds(obj, idsList) は、指定された断面リストIDに
%   対する各変数の下限値を計算します。各変数タイプ（H, B, tw, tf, 
%   D, t等）の最小値を計算し、該当しない変数にはNaNを設定します。
%
%   入力引数:
%     idsList - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     lb - 下限値ベクトル [1×nxvar]
%          該当しない変数はNaN
%
%   例:
%     lb = validator.getLowerBounds(1);
%
%   参考:
%     getUpperBounds, computeBounds

% computeBoundsメソッドを使用して下限値を計算
lb = obj.computeBounds(idsList, 'lower');

return
end