function sectionType = getSectionType(obj, idslist)
%getSectionType 断面リストから断面タイプを取得
%   sectionType = getSectionType(obj, idslist) は、
%   断面リストIDから対応する断面タイプを返します。
%
%   入力引数:
%     idslist - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     sectionType - 断面タイプ (PRM.WFS/HSS/BRB/RCRS)
%
%   参考:
%     getNominalH, getNominalB, SectionStandardAccessor

% 範囲チェック
if idslist < 1 || idslist > obj.secList_.nlist
  error('SectionStandardAccessor:InvalidListId', ...
    '無効な断面リストID: %d (有効範囲: 1～%d)', ...
    idslist, obj.secList_.nlist);
end

% secListから断面タイプを取得
sectionType = obj.secList_.section_type(idslist);

return
end