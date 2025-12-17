function val = getStandardTf(obj, idsList)
% getStandardTf - H形鋼のtf規格値を取得
%
% H形鋼（WFS）断面リストのフランジ厚さ規格値を取得する。
% 規格で定められた実際の寸法値を返す。
%
% 入力:
%   idsList - 断面リストID（スカラー）
%
% 出力:
%   val - tf規格値の配列（1 x n）
%         WFS以外の断面タイプの場合は空配列

if obj.secList_.section_type(idsList) == PRM.WFS
  secdim = obj.secList_.getDimension(idsList, obj.idPhase_);
  val = unique(secdim(:,PRM.SECDIM_WFS_TF))';
else
  val = [];
end

return
end