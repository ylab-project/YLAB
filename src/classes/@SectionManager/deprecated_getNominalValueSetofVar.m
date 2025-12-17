function vset = deprecated_getNominalValueSetofVar(secmgr, idvar)
%deprecated_getNominalValueSetofVar 変数の公称値セット取得（非推奨）
%   vset = deprecated_getNominalValueSetofVar(secmgr, idvar) は、
%   指定された変数IDに対応する全断面リストの公称値セットを返します。
%
%   この関数は非推奨です。代わりにgetNominalValueSetofVar
%   （StandardAccessorに委譲）を使用してください。
%
%   入力引数:
%     idvar - 変数ID (スカラー整数)
%
%   出力引数:
%     vset - 公称値セット [n×1] 配列
%            該当する公称値がない場合は空配列
%
%   参考:
%     getNominalValueSetofVar, SectionStandardAccessor.getNominalValueSetofVar

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getNominalValueSetofVar は非推奨です。' ...
   '代わりに getNominalValueSetofVar を使用してください。']);

% 旧実装（変更なし）
vset = [];
vtype = secmgr.idvar2vtype(idvar);
idset = secmgr.getIdSlistofVar(idvar);
if isempty(idset)
  return
end
for idslist = idset
  switch vtype
    case PRM.WFS_H
      vset = [vset; secmgr.getHnominal(idslist)];
    case PRM.WFS_B
      vset = [vset; secmgr.getBnominal(idslist)];
    otherwise
      return
  end
end
vset = unique(vset);

return
end