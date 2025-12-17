function idwfs2slist = mapWfsToSectionList(obj)
%mapWfsToSectionList 全WFS断面の断面リストIDマッピングを取得
%   idwfs2slist = mapWfsToSectionList(obj) は、全WFS断面に対する
%   断面リストIDマッピングを返します。
%
%   出力引数:
%     idwfs2slist - WFS断面→断面リストID [nwfs×1]
%
%   例:
%     idwfs2slist = mapper.mapWfsToSectionList();
%
%   参考:
%     mapHssToSectionList, mapBrbsToSectionList, lookupSectionListId

if obj.nwfs == 0
  idwfs2slist = [];
  return;
end

% WFS断面IDを全体断面IDに変換して断面リストIDを取得
idwfs2sec = obj.mapWfsToSection();
idwfs2slist = obj.idSectionList_(idwfs2sec);

return
end