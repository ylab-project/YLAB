function idreprcrs2rcrs = mapRepresentativeToRcrs(obj)
%mapRepresentativeToRcrs 代表RCRS断面からRCRS断面への変換
%   idreprcrs2rcrs = mapRepresentativeToRcrs(obj) は、
%   代表RCRS断面IDから対応するRCRS断面IDへのマッピング配列を返します。
%   各代表RCRS断面に対して最初のRCRS断面IDを返します。
%
%   出力引数:
%     idreprcrs2rcrs - 代表RCRS断面→RCRS断面 [nreprcrs×1]
%
%   参考:
%     mapRcrsToRepresentative, mapRepresentativeToWfs, mapRepresentativeToHss

% RCRS断面の代表断面を取得
[~, idreprcrs2rcrs] = unique(obj.idsec2srep_(obj.idsec2stype_ == PRM.RCRS));

return
end