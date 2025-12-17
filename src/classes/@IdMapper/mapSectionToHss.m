function idsec2hss = mapSectionToHss(obj)
%mapSectionToHss 全断面のHSS断面IDマッピングを取得
%   idsec2hss = mapSectionToHss(obj) は、全断面に対するHSS断面ID
%   マッピングを返します。HSS断面でない場合は0を返します。
%
%   出力引数:
%     idsec2hss - HSS断面IDマッピング [nsec×1]
%                 HSS断面でない場合は0
%
%   例:
%     idsec2hss = mapper.mapSectionToHss();
%
%   参考:
%     mapHssToSection, mapSectionToWfs

idsec2hss = zeros(obj.nsec, 1);
idsec2hss(obj.idsec2stype_ == PRM.HSS) = 1:obj.nhss;

return
end