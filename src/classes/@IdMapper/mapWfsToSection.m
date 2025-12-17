function idwfs2sec = mapWfsToSection(obj)
%mapWfsToSection 全WFS断面の断面IDマッピングを取得
%   idwfs2sec = mapWfsToSection(obj) は、全WFS断面に対する
%   断面IDマッピングを返します。
%
%   出力引数:
%     idwfs2sec - WFS断面→断面IDマッピング [nwfs×1]
%
%   例:
%     idwfs2sec = mapper.mapWfsToSection();
%
%   参考:
%     mapSectionToWfs, mapHssToSection

% 全断面からWFS断面のインデックスを取得
idwfs2sec = find(obj.idsec2stype_ == PRM.WFS);

return
end