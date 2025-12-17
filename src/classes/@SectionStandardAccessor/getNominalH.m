function val = getNominalH(obj, idsList)
% getNominalH - H形鋼のH公称値を取得
%
% H形鋼（WFS）断面リストのH寸法公称値（呼び寸法）を取得する。
% 例: H400x200の場合、400を返す。
%
% 入力:
%   idsList - 断面リストID（スカラー）
%
% 出力:
%   val - H公称値の配列（1 x n）
%         WFS以外の断面タイプの場合は空配列

if obj.secList_.section_type(idsList) == PRM.WFS
  secdim = obj.secList_.getDimension(idsList, obj.idPhase_);
  val = unique(secdim(:,PRM.SECDIM_WFS_H_NOM))';
else
  val = [];
end

return
end