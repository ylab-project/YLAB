function idbrbs2sec = mapBrbsToSection(obj)
%mapBrbsToSection 全BRB断面の断面IDマッピングを取得
%   idbrbs2sec = mapBrbsToSection(obj) は、全BRB断面に対する
%   断面IDマッピングを返します。
%
%   出力引数:
%     idbrbs2sec - BRB断面→断面IDマッピング [nbrbs×1]
%
%   例:
%     idbrbs2sec = mapper.mapBrbsToSection();
%
%   参考:
%     mapSectionToBrbs, mapWfsToSection

% 全断面からBRB断面のインデックスを取得
idbrbs2sec = find(obj.idsec2stype_ == PRM.BRB);

return
end