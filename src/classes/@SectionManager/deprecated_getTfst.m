function val = deprecated_getTfst(obj, idsList)
% 【非推奨】H形鋼のtf規格値を取得
%
% このメソッドは非推奨です。
% 代わりに obj.standardAccessor.getStandardTf(idsList) を使用してください。
%
% Syntax:
%   val = obj.deprecated_getTfst(idsList)
%
% Inputs:
%   obj - SectionManagerオブジェクト
%   idsList - 断面リストID
%
% Outputs:
%   val - tf規格値のベクトル

% 非推奨警告を表示
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getTfst は非推奨です。\n' ...
  '代わりに obj.standardAccessor.getStandardTf(idsList) ' ...
  'を使用してください。']);

% 元の実装を保持（新旧比較テストのため）
if obj.secList.section_type(idsList) == PRM.WFS
  secdim = obj.getDimension(idsList);
  val = unique(secdim(:,4))';
else
  val = [];
end

return
end