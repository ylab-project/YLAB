function idrcrs2sec = mapRcrsToSection(obj)
%mapRcrsToSection 全RCRS断面の断面IDマッピングを取得
%   idrcrs2sec = mapRcrsToSection(obj) は、全RCRS断面に対する
%   断面IDマッピングを返します。
%
%   出力引数:
%     idrcrs2sec - RCRS断面→断面IDマッピング [nrcrs×1]
%
%   例:
%     idrcrs2sec = mapper.mapRcrsToSection();
%
%   参考:
%     mapSectionToRcrs, mapWfsToSection

% 全断面からRCRS断面のインデックスを取得
idrcrs2sec = find(obj.idsec2stype_ == PRM.RCRS);

return
end