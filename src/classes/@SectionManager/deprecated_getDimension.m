function dimension = deprecated_getDimension(secmgr, idList, idphase)
%deprecated_getDimension 断面寸法を取得（非推奨）
%   dimension = deprecated_getDimension(secmgr, idList, idphase) は、
%   指定された断面IDリストの寸法を取得します。
%
%   非推奨: このメソッドは非推奨です。
%   代わりにstandardAccessor.getSectionDimension()を使用してください。
%
%   入力引数:
%     idList  - 断面IDリスト
%     idphase - フェーズID（省略可能、既定値: secmgr.idphase）
%
%   参考:
%     SectionListHandler.getDimension, 
%     SectionStandardAccessor.getSectionDimension

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  'deprecated_getDimension は非推奨です。standardAccessor.getSectionDimension() を使用してください。');

% 元の実装を保持（新旧比較テストのため）
if nargin == 2
  idphase = secmgr.idphase;
end
dimension = secmgr.secList.getDimension(idList, idphase);

return
end