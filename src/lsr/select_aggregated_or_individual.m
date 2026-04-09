function xlist = select_aggregated_or_individual(xlist, xvar0, ...
  xvar_agg)
%select_aggregated_or_individual - 集約候補で個別候補を置換する
%
%   xlist = select_aggregated_or_individual(xlist, xvar0, xvar_agg)
%   は、事前計算済みの集約候補 xvar_agg で個別候補行列 xlist を
%   置換する。cgsr / jbs の restore 関数末尾で共通して使う。
%
%   呼び出し側の契約: `do_aggregated_restore=true` の場合のみ本関数
%   を呼ぶこと。OFF 時は呼び出し側で xlist をそのまま使用する。
%
%   仕様 (cgsr_aggregation_spec.md §4.0):
%     - xvar_agg ~= xvar0: xvar_agg 1 行のみに置換
%     - xvar_agg == xvar0 (空振り): 個別候補 xlist をそのまま返す
%
%   入力引数:
%     xlist    - 個別候補の行列 [nlist x nvar]
%     xvar0    - 集約の基点となる現解 [1 x nvar]
%     xvar_agg - 事前計算済みの集約候補 [1 x nvar]
%
%   出力引数:
%     xlist - 置換後の行列（空振り時は入力のまま）

if ~isequal(xvar_agg, xvar0)
  xlist = xvar_agg;
end

return
end
