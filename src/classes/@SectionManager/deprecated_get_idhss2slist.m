function idhss2slist = deprecated_get_idhss2slist(secmgr)
%deprecated_get_idhss2slist HSS断面の断面リストID取得（旧実装）
%   idhss2slist = deprecated_get_idhss2slist(secmgr) は、
%   HSS断面の断面リストIDを返します。
%
%   この関数は非推奨です。get.idhss2slistを使用してください。
%
%   出力引数:
%     idhss2slist - HSS断面の断面リストID [nhss×1]

% 旧実装（変更なし）
idhss2slist = secmgr.idSectionList;
idhss2slist = idhss2slist(secmgr.idsec2stype==PRM.HSS);

return
end