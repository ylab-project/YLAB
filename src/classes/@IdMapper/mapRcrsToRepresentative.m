function idrcrs2reprcrs = mapRcrsToRepresentative(obj)
%mapRcrsToRepresentative 全RCRS断面の代表RCRS断面IDマッピングを取得
%   idrcrs2reprcrs = mapRcrsToRepresentative(obj) は、全RCRS断面に対する
%   代表RCRS断面IDマッピングを返します。
%
%   出力引数:
%     idrcrs2reprcrs - RCRS断面→代表RCRS断面IDマッピング [nrcrs×1]
%
%   例:
%     idrcrs2reprcrs = mapper.mapRcrsToRepresentative();
%
%   参考:
%     mapWfsToRepresentative, mapSectionToRcrs

if obj.nrcrs == 0
  idrcrs2reprcrs = [];
  return;
end

% RCRS断面のみを抽出してuniqueで代表断面への変換
[~, ~, idrcrs2reprcrs] = ...
  unique(obj.idsec2srep_(obj.idsec2stype_ == PRM.RCRS));

return
end