function idwfs2repwfs = deprecated_get_idwfs2repwfs(secmgr)
%deprecated_get_idwfs2repwfs WFS断面の代表断面ID取得（旧実装）
%   idwfs2repwfs = deprecated_get_idwfs2repwfs(secmgr) は、
%   WFS断面IDを代表WFS断面IDに変換します。
%
%   この関数は非推奨です。get.idwfs2repwfsを使用してください。
%
%   出力引数:
%     idwfs2repwfs - WFS断面→代表WFS断面ID [nwfs×1]

% 旧実装（変更なし）
[~, ~, idwfs2repwfs] = ...
  unique(secmgr.idsec2srep(secmgr.idsec2stype==PRM.WFS));

return
end