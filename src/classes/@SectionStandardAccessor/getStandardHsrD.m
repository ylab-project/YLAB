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
  secdim = obj.secList_.getDimension(idsList, obj.idPhase_);
  val = unique(secdim(:,1))';  % 第1列が外径D
else
  val = [];
end
return
end