function idrepwfs2sec = mapRepresentativeWfsToSection(obj)
%mapRepresentativeWfsToSection 代表WFS断面から断面への変換
%   idrepwfs2sec = mapRepresentativeWfsToSection(obj) は、
%   代表WFS断面IDから対応する断面IDへのマッピングを返します。
%
%   出力引数:
%     idrepwfs2sec - 代表WFS断面→断面 [nrepwfs×1]
%
%   参考:
%     mapRepresentativeWfsToVariable, mapRepresentativeToWfs

idsrep2sec = obj.mapRepresentativeToSection();
idsrep2stype = obj.mapRepresentativeToSectionType();
idrepwfs2sec = idsrep2sec(idsrep2stype == PRM.WFS);

return
end