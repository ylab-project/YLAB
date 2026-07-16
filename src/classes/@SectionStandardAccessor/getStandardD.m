function val = getStandardD(obj, idsList)
% getStandardD - HSS断面のD規格値を取得
%
% HSS（鋼管）断面リストの外径規格値を取得する。
% 規格で定められた実際の寸法値を返す。
%
% 入力:
%   idsList - 断面リストID（スカラー）
%
% 出力:
%   val - D規格値の配列（1 x n）
%         HSS以外の断面タイプの場合は空配列

if obj.secList_.section_type(idsList) == PRM.HSS
  val = obj.secList_.getDimensionValues(idsList, PRM.SECDIM_HSS_D, ...
    obj.idPhase_);
else
  val = [];
end

return
end