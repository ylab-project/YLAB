function idsec2rcrs = mapSectionToRcrs(obj)
%mapSectionToRcrs 全断面のRCRS断面IDマッピングを取得
%   idsec2rcrs = mapSectionToRcrs(obj) は、全断面に対するRCRS断面ID
%   マッピングを返します。RCRS断面でない場合は0を返します。
%
%   出力引数:
%     idsec2rcrs - RCRS断面IDマッピング [nsec×1]
%                  RCRS断面でない場合は0
%
%   例:
%     idsec2rcrs = mapper.mapSectionToRcrs();
%
%   参考:
%     mapRcrsToSection, mapSectionToWfs

idsec2rcrs = zeros(obj.nsec, 1);
idsec2rcrs(obj.idsec2stype_ == PRM.RCRS) = 1:obj.nrcrs;

return
end