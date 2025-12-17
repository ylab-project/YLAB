function idsec2brbs = mapSectionToBrbs(obj)
%mapSectionToBrbs 全断面のBRB断面IDマッピングを取得
%   idsec2brbs = mapSectionToBrbs(obj) は、全断面に対するBRB断面ID
%   マッピングを返します。BRB断面でない場合は0を返します。
%
%   出力引数:
%     idsec2brbs - BRB断面IDマッピング [nsec×1]
%                  BRB断面でない場合は0
%
%   例:
%     idsec2brbs = mapper.mapSectionToBrbs();
%
%   参考:
%     mapBrbsToSection, mapSectionToWfs

idsec2brbs = zeros(obj.nsec, 1);
idsec2brbs(obj.idsec2stype_ == PRM.BRB) = 1:obj.nbrbs;

return
end