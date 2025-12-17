function st = deprecated_getHst(secmgr, idslist)
% deprecated_getHst - H寸法の規格値を取得（非推奨）
%
% この関数は非推奨です。代わりにstandardAccessor.getStandardHを
% 使用してください。
%
% See also: getStandardH

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getHst は非推奨です。' ...
   '代わりに standardAccessor.getStandardH を使用してください。']);

% 元の実装をそのまま実行
if secmgr.secList.section_type(idslist) == PRM.WFS
  secdim = secmgr.getDimension(idslist);
  st = unique(secdim(:,1))';
else
  st = [];
end

return
end