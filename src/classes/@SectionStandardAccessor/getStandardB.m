function val = getStandardB(obj, idsList)
% getStandardB - WFS断面のB規格値（実寸法）を取得
%
% WFS（H形鋼）断面リストのB寸法規格値（実寸法）を取得する。
% 規格で定められた実際の寸法値を返す。
%
% 入力:
%   idsList - 断面リストID（スカラー）
%
% 出力:
%   val - B規格値の配列（1 x n）
%         WFS以外の断面タイプの場合は空配列

if obj.secList_.section_type(idsList) == PRM.WFS
  secdim = obj.secList_.getDimension(idsList, obj.idPhase_);
  val = unique(secdim(:,PRM.SECDIM_WFS_B))';
else
  val = [];
end

return
end