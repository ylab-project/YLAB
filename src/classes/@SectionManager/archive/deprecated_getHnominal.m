function val = deprecated_getHnominal(obj, idsList)
% 【非推奨】H形鋼のH公称値を取得
%
% このメソッドは非推奨です。
% 代わりに obj.standardAccessor.getNominalH(idsList) を使用してください。
%
% Syntax:
%   val = obj.deprecated_getHnominal(idsList)
%
% Inputs:
%   obj - SectionManagerオブジェクト
%   idsList - 断面リストID
%
% Outputs:
%   val - H公称値のベクトル

% 非推奨警告を表示
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getHnominal は非推奨です。\n' ...
  '代わりに obj.standardAccessor.getNominalH(idsList) ' ...
  'を使用してください。']);

% 元の実装を保持（新旧比較テストのため）
if obj.secList.section_type(idsList) == PRM.WFS
  secdim = obj.getDimension(idsList);
  val = unique(secdim(:,6))';
else
  val = [];
end

return
end