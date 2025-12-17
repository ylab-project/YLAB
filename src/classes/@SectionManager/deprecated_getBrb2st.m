function val = deprecated_getBrb2st(obj, idsList)
% 【非推奨】BRB断面のV2規格値を取得
%
% このメソッドは非推奨です。
% 代わりに obj.standardAccessor.getStandardV2(idsList) を使用してください。
%
% Syntax:
%   val = obj.deprecated_getBrb2st(idsList)
%
% Inputs:
%   obj - SectionManagerオブジェクト
%   idsList - 断面リストID
%
% Outputs:
%   val - V2規格値のベクトル

% 非推奨警告を表示
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getBrb2st は非推奨です。\n' ...
  '代わりに obj.standardAccessor.getStandardV2(idsList) ' ...
  'を使用してください。']);

% 元の実装を保持（新旧比較テストのため）
if obj.secList.section_type(idsList) == PRM.BRB
  secdim = obj.getDimension(idsList);
  val = unique(secdim(:,2))';
else
  val = [];
end

return
end