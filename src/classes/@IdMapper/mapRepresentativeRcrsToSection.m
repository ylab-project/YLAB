function idreprcrs2sec = mapRepresentativeRcrsToSection(obj)
%mapRepresentativeRcrsToSection 代表RCRS断面から断面への変換
%   idreprcrs2sec = mapRepresentativeRcrsToSection(obj) は、
%   代表RCRS断面IDから対応する断面IDへのマッピングを返します。
%
%   出力引数:
%     idreprcrs2sec - 代表RCRS断面→断面 [nreprcrs×1]
%
%   参考:
%     mapRepresentativeToRcrs

idsrep2sec = obj.mapRepresentativeToSection();
idsrep2stype = obj.mapRepresentativeToSectionType();
idreprcrs2sec = idsrep2sec(idsrep2stype == PRM.RCRS);

return
end