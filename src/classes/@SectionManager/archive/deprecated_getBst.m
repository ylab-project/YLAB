function st = deprecated_getBst(secmgr, idslist)
% deprecated_getBst - B寸法の規格値を取得（非推奨）
%
% この関数は非推奨です。代わりにstandardAccessor.getStandardBを
% 使用してください。
%
% See also: getStandardB

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getBst は非推奨です。' ...
   '代わりに standardAccessor.getStandardB を使用してください。']);

% 元の実装をそのまま実行
if secmgr.secList.section_type(idslist) == PRM.WFS
  secdim = secmgr.getDimension(idslist);
  st = unique(secdim(:,2))';
else
  st = [];
end

return
end