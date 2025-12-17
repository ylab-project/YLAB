function val = deprecated_getDst(obj, idsList)
% 【非推奨】HSS断面のD規格値を取得
%
% このメソッドは非推奨です。
% 代わりに obj.standardAccessor.getStandardD(idsList) を使用してください。
%
% Syntax:
%   val = obj.deprecated_getDst(idsList)
%
% Inputs:
%   obj - SectionManagerオブジェクト
%   idsList - 断面リストID
%
% Outputs:
%   val - D規格値のベクトル

% 非推奨警告を表示
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getDst は非推奨です。\n' ...
  '代わりに obj.standardAccessor.getStandardD(idsList) ' ...
  'を使用してください。']);

% 元の実装を保持（新旧比較テストのため）
if obj.secList.section_type(idsList) == PRM.HSS
  secdim = obj.getDimension(idsList);
  val = unique(secdim(:,1))';
else
  val = [];
end

return
end