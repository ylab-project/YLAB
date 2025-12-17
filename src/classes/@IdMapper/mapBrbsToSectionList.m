function idbrbs2slist = mapBrbsToSectionList(obj)
%mapBrbsToSectionList 全BRB断面の断面リストIDマッピングを取得
%   idbrbs2slist = mapBrbsToSectionList(obj) は、全BRB断面に対する
%   断面リストIDマッピングを返します。
%
%   出力引数:
%     idbrbs2slist - BRB断面→断面リストID [nbrbs×1]
%
%   例:
%     idbrbs2slist = mapper.mapBrbsToSectionList();
%
%   参考:
%     mapWfsToSectionList, mapHssToSectionList, lookupSectionListId

if obj.nbrbs == 0
  idbrbs2slist = [];
  return;
end

% BRB断面IDを全体断面IDに変換して断面リストIDを取得
idbrbs2sec = obj.mapBrbsToSection();
idbrbs2slist = obj.idSectionList_(idbrbs2sec);

return
end