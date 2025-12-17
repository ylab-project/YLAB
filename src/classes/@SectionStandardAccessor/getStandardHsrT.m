function val = getStandardHsrT(obj, idsList)
%getStandardHsrT - HSR断面のt規格値を取得
%
% HSR（円形鋼管）断面リストの板厚規格値を取得する。
%
% 入力:
%   idsList - 断面リストID（スカラー）
%
% 出力:
%   val - t規格値の配列（1 x n）

if obj.secList_.section_type(idsList) == PRM.HSR
  secdim = obj.secList_.getDimension(idsList, obj.idPhase_);
  val = unique(secdim(:,2))';  % 第2列が板厚t
else
  val = [];
end
return
end