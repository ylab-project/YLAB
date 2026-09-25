function idsec2hsr = mapSectionToHsr(obj)
%mapSectionToHsr 全断面のHSR断面IDマッピングを取得
%   idsec2hsr = mapSectionToHsr(obj) は、全断面に対するHSR断面ID
%   マッピングを返します。HSR断面でない場合は0を返します。
%
%   出力引数:
%     idsec2hsr - HSR断面IDマッピング [nsec×1]
%                 HSR断面でない場合は0
%
%   例:
%     idsec2hsr = mapper.mapSectionToHsr();

idsec2hsr = zeros(obj.nsec, 1);
idsec2hsr(obj.idsec2shape_ == PRM.HSR) = 1:obj.nhsr;

return
end