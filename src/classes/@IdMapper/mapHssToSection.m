function idhss2sec = mapHssToSection(obj)
%mapHssToSection 全HSS断面の断面IDマッピングを取得
%   idhss2sec = mapHssToSection(obj) は、全HSS断面に対する
%   断面IDマッピングを返します。
%
%   出力引数:
%     idhss2sec - HSS断面→断面IDマッピング [nhss×1]
%
%   例:
%     idhss2sec = mapper.mapHssToSection();
%
%   参考:
%     mapSectionToHss, mapWfsToSection

% 全断面からHSS断面のインデックスを取得
idhss2sec = find(obj.idsec2stype_ == PRM.HSS);

return
end