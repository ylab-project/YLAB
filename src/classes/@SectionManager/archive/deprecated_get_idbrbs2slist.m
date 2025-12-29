function idbrbs2slist = deprecated_get_idbrbs2slist(secmgr)
%deprecated_get_idbrbs2slist BRB断面の断面リストID取得（旧実装）
%   idbrbs2slist = deprecated_get_idbrbs2slist(secmgr) は、
%   BRB断面の断面リストIDを返します。
%
%   この関数は非推奨です。get.idbrbs2slistを使用してください。
%
%   出力引数:
%     idbrbs2slist - BRB断面の断面リストID [nbrbs×1]

% 旧実装（変更なし）
idbrbs2slist = secmgr.idSectionList;
idbrbs2slist = idbrbs2slist(secmgr.idsec2stype==PRM.BRB);

return
end