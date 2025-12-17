function idrephss2sec = mapRepresentativeHssToSection(obj)
%mapRepresentativeHssToSection 代表HSS断面から断面への変換
%   idrephss2sec = mapRepresentativeHssToSection(obj) は、
%   代表HSS断面IDから対応する断面IDへのマッピングを返します。
%
%   出力引数:
%     idrephss2sec - 代表HSS断面→断面 [nrephss×1]
%
%   参考:
%     mapRepresentativeHssToVariable, mapRepresentativeToHss

idsrep2sec = obj.mapRepresentativeToSection();
idsrep2stype = obj.mapRepresentativeToSectionType();
idrephss2sec = idsrep2sec(idsrep2stype == PRM.HSS);

return
end