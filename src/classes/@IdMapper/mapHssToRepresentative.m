function idhss2rephss = mapHssToRepresentative(obj)
%mapHssToRepresentative 全HSS断面の代表HSS断面IDマッピングを取得
%   idhss2rephss = mapHssToRepresentative(obj) は、全HSS断面に対する
%   代表HSS断面IDマッピングを返します。
%
%   出力引数:
%     idhss2rephss - HSS断面→代表HSS断面IDマッピング [nhss×1]
%
%   例:
%     idhss2rephss = mapper.mapHssToRepresentative();
%
%   参考:
%     mapWfsToRepresentative, mapSectionToHss

if obj.nhss == 0
  idhss2rephss = [];
  return;
end

% HSS断面のみを抽出してuniqueで代表断面への変換
[~, ~, idhss2rephss] = unique(obj.idsec2srep_(obj.idsec2stype_ == PRM.HSS));

return
end