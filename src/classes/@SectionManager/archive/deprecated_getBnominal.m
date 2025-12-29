function val = deprecated_getBnominal(obj, idsList)
% 【非推奨】H形鋼のB公称値を取得
%
% このメソッドは非推奨です。
% 代わりに obj.standardAccessor.getNominalB(idsList) を使用してください。
%
% Syntax:
%   val = obj.deprecated_getBnominal(idsList)
%
% Inputs:
%   obj - SectionManagerオブジェクト
%   idsList - 断面リストID
%
% Outputs:
%   val - B公称値のベクトル

% 非推奨警告を表示
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getBnominal は非推奨です。\n' ...
  '代わりに obj.standardAccessor.getNominalB(idsList) ' ...
  'を使用してください。']);

% 元の実装を保持（新旧比較テストのため）
if obj.secList.section_type(idsList) == PRM.WFS
  secdim = obj.getDimension(idsList);
  val = unique(secdim(:,7))';
else
  val = [];
end

return
end