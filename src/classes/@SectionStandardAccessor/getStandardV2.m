function val = getStandardV2(obj, idsList)
% getStandardV2 - BRB断面のV2規格値を取得
%
% BRB（座屈拘束ブレース）断面リストのV2寸法規格値を取得する。
% 規格で定められた実際の寸法値を返す。
%
% 入力:
%   idsList - 断面リストID（スカラー）
%
% 出力:
%   val - V2規格値の配列（1 x n）
%         BRB以外の断面タイプの場合は空配列

if obj.secList_.section_type(idsList) == PRM.BRB
  secdim = obj.secList_.getDimension(idsList, obj.idPhase_);
  val = unique(secdim(:,PRM.SECDIM_BRB_V2))';
else
  val = [];
end

return
end