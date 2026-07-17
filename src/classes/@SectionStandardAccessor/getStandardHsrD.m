function val = getStandardHsrD(obj, idsList)
%getStandardHsrD - HSR断面のD規格値を取得
%
% HSR（円形鋼管）断面リストの外径規格値を取得する。
%
% 入力:
%   idsList - 断面リストID（スカラー）
%
% 出力:
%   val - D規格値の配列（1 x n）

if obj.secList_.section_type(idsList) == PRM.HSR
  val = obj.secList_.getDimensionValues(idsList, PRM.SECDIM_HSR_D, ...
    obj.idPhase_);
else
  val = [];
end
return
end