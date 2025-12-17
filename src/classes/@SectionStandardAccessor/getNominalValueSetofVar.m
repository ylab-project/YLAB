function vset = getNominalValueSetofVar(obj, idvar, idMapper, idsec2var)
%getNominalValueSetofVar 変数の公称値セット取得
%   vset = getNominalValueSetofVar(obj, idvar, idMapper, idsec2var) は、
%   指定された変数IDに対応する全断面リストの公称値セットを返します。
%   変数タイプ（H, B等）に応じて適切な公称値を収集し、重複を除去した
%   セットを返します。
%
%   入力引数:
%     idvar - 変数ID (スカラー整数)
%     idMapper - IdMapperインスタンス（変数タイプ・断面リスト取得用）
%     idsec2var - 断面→変数マッピング配列 [nsec×ndim]
%
%   出力引数:
%     vset - 公称値セット [n×1] 配列
%            該当する公称値がない場合は空配列
%
%   例:
%     vset = accessor.getNominalValueSetofVar(5, idMapper, idsec2var);
%
%   参考:
%     getNominalH, getNominalB, getIdSlistofVar

vset = [];

% 変数タイプを取得
if ~isempty(idMapper) && idvar > 0 && idvar <= length(idMapper.idvar2vtype)
  vtype = idMapper.idvar2vtype(idvar);
else
  return  % 無効な変数ID
end

% 変数が使用される断面リストIDを取得
idset = idMapper.getIdSlistofVar(idvar);
if isempty(idset)
  return  % 該当する断面リストなし
end

% 各断面リストから公称値を収集
for idslist = idset
  switch vtype
    case PRM.WFS_H
      vset = [vset; obj.getNominalH(idslist)];
    case PRM.WFS_B
      vset = [vset; obj.getNominalB(idslist)];
    otherwise
      % H, B以外の変数タイプは未対応
      return
  end
end

% 重複を除去してソート
vset = unique(vset);

return
end