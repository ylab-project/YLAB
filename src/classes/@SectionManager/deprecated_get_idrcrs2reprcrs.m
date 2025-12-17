function idrcrs2reprcrs = deprecated_get_idrcrs2reprcrs(secmgr)
%deprecated_get_idrcrs2reprcrs RCRS断面の代表断面ID取得（旧実装）
%   idrcrs2reprcrs = deprecated_get_idrcrs2reprcrs(secmgr) は、
%   RCRS断面IDを代表RCRS断面IDに変換します。
%
%   この関数は非推奨です。get.idrcrs2reprcrsを使用してください。
%
%   出力引数:
%     idrcrs2reprcrs - RCRS断面→代表RCRS断面ID [nrcrs×1]

% 旧実装（変更なし）
[~, ~, idrcrs2reprcrs] = ...
  unique(secmgr.idsec2srep(secmgr.idsec2stype==PRM.RCRS));

return
end