function [cvec, result, restoration] = analysis_constraint_xvar( ...
  xvar, com, options)
%analysis_constraint_xvar - 設計変数のみから制約を評価する
%
%   [cvec, result, restoration] =
%     analysis_constraint_xvar(xvar, com, options) は、設計変数から
%   断面寸法を写像し、得られた評価ペアで analysis_constraint を
%   実行する。写像済み断面を持たない境界で使用する。
%
%   入力引数:
%     xvar    - 設計変数ベクトル [nvar×1]
%     com     - 共通データ構造体
%     options - 解析オプション構造体
%
%   出力引数:
%     cvec        - 制約値ベクトル [1×ncon]（正の値が制約違反）
%     result      - 詳細結果構造体（応力、変形、諸元等）
%     restoration - 復元用データ構造体
%
%   備考:
%     - xvar は正規化せず、渡された評価点のまま写像する。
%     - nargout をそのまま本体へ転送する。要求出力数で本体を呼ぶこと
%       で、候補評価では完全結果を生成せず出力分離を保つ。
%     - 関連関数: analysis_constraint

secdim = com.secmgr.findNearestSection(xvar, options);
outc = cell(1, max(1, nargout));
[outc{:}] = analysis_constraint(xvar, secdim, com, options);
cvec = outc{1};
if nargout >= 2
  result = outc{2};
end
if nargout >= 3
  restoration = outc{3};
end

return
end
