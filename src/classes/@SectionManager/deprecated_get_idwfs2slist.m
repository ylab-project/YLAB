function idwfs2slist = deprecated_get_idwfs2slist(secmgr)
%deprecated_get_idwfs2slist WFS断面の断面リストID取得（旧実装）
%   idwfs2slist = deprecated_get_idwfs2slist(secmgr) は、
%   WFS断面の断面リストIDを返します。
%
%   この関数は非推奨です。get.idwfs2slistを使用してください。
%
%   出力引数:
%     idwfs2slist - WFS断面の断面リストID [nwfs×1]

% 旧実装（変更なし）
idwfs2slist = secmgr.idSectionList;
idwfs2slist = idwfs2slist(secmgr.idsec2stype==PRM.WFS);

return
end