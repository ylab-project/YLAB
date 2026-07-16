function val = getNominalB(obj, idsList)
% getNominalB - H形鋼のB公称値を取得
%
% H形鋼（WFS）断面リストのB寸法公称値（呼び寸法）を取得する。
% 例: H400x200の場合、200を返す。
%
% 入力:
%   idsList - 断面リストID（スカラー）
%
% 出力:
%   val - B公称値の配列（1 x n）
%         WFS以外の断面タイプの場合は空配列

if obj.secList_.section_type(idsList) == PRM.WFS
  val = obj.secList_.getDimensionValues(idsList, PRM.SECDIM_WFS_B_NOM, ...
    obj.idPhase_);
else
  val = [];
end

return
end