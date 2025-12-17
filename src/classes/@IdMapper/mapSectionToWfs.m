function idsec2wfs = mapSectionToWfs(obj)
%mapSectionToWfs 全断面のWFS断面IDマッピングを取得
%   idsec2wfs = mapSectionToWfs(obj) は、全断面に対するWFS断面ID
%   マッピングを返します。WFS断面でない場合は0を返します。
%
%   出力引数:
%     idsec2wfs - WFS断面IDマッピング [nsec×1]
%                 WFS断面でない場合は0
%
%   例:
%     idsec2wfs = mapper.mapSectionToWfs();
%
%   参考:
%     mapWfsToSection, mapSectionToHss

idsec2wfs = zeros(obj.nsec, 1);
idsec2wfs(obj.idsec2stype_ == PRM.WFS) = 1:obj.nwfs;

return
end