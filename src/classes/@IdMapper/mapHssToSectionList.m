function idhss2slist = mapHssToSectionList(obj)
%mapHssToSectionList 全HSS断面の断面リストIDマッピングを取得
%   idhss2slist = mapHssToSectionList(obj) は、全HSS断面に対する
%   断面リストIDマッピングを返します。
%
%   出力引数:
%     idhss2slist - HSS断面→断面リストID [nhss×1]
%
%   例:
%     idhss2slist = mapper.mapHssToSectionList();
%
%   参考:
%     mapWfsToSectionList, mapBrbsToSectionList, lookupSectionListId

if obj.nhss == 0
  idhss2slist = [];
  return;
end

% HSS断面IDを全体断面IDに変換して断面リストIDを取得
idhss2sec = obj.mapHssToSection();
idhss2slist = obj.idSectionList_(idhss2sec);

return
end