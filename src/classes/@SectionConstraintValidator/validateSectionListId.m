function validateSectionListId(obj, idsList)
%validateSectionListId 断面リストIDの妥当性を検証
%   validateSectionListId(obj, idsList) は、実行時の断面リストID引数の
%   妥当性を検証します。secListが空でないこと、idsListが有効な範囲内に
%   あることを確認します。
%
%   入力引数:
%     idsList - 断面リストID (スカラー整数、1～nlist)
%
%   エラー条件:
%     SectionConstraintValidator:EmptySecList - secListが空
%     SectionConstraintValidator:InvalidSectionListId - 無効な断面リストID
%
%   参考:
%     SectionConstraintValidator, extractValidSectionFlags

% secListが空でないことを確認
if obj.isSecListEmpty()
  error('SectionConstraintValidator:EmptySecList', ...
    'secListが空です');
end

% 断面リストIDの妥当性を確認
if nargin < 2 || ~isnumeric(idsList) || ...
    ~isscalar(idsList) || idsList < 1 || idsList > obj.nlist
  error('SectionConstraintValidator:InvalidSectionListId', ...
    '有効な断面リストID (1-%d) が必要です', obj.nlist);
end

return
end