function idsrep2stype = mapRepresentativeToSectionType(obj)
%mapRepresentativeToSectionType 代表断面から断面タイプへの変換
%   idsrep2stype = mapRepresentativeToSectionType(obj) は、
%   すべての代表断面IDから対応する断面タイプへのマッピングを返します。
%
%   出力引数:
%     idsrep2stype - 代表断面→断面タイプ [nsrep×1]
%
%   参考:
%     mapRepresentativeToSection

idsrep2sec = obj.mapRepresentativeToSection();
idsrep2stype = obj.idsec2stype_(idsrep2sec);

return
end