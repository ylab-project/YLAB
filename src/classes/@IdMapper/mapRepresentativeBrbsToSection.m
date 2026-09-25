function idrepbrbs2sec = mapRepresentativeBrbsToSection(obj)
%mapRepresentativeBrbsToSection 代表BRB断面から断面への変換
%   idrepbrbs2sec = mapRepresentativeBrbsToSection(obj) は、
%   代表BRB断面IDから対応する断面IDへのマッピングを返します。
%
%   出力引数:
%     idrepbrbs2sec - 代表BRB断面→断面 [nrepbrbs×1]
%
%   参考:
%     mapRepresentativeBrbsToVariable, mapRepresentativeToBrbs

idsrep2sec = obj.mapRepresentativeToSection();
idrepbrbs2sec = idsrep2sec(obj.idsrep2shape_ == PRM.BRB);

return
end