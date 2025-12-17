function idbrbs2repbrbs = deprecated_get_idbrbs2repbrbs(secmgr)
%deprecated_get_idbrbs2repbrbs BRB断面の代表断面ID取得（旧実装）
%   idbrbs2repbrbs = deprecated_get_idbrbs2repbrbs(secmgr) は、
%   BRB断面IDを代表BRB断面IDに変換します。
%
%   この関数は非推奨です。get.idbrbs2repbrbsを使用してください。
%
%   出力引数:
%     idbrbs2repbrbs - BRB断面→代表BRB断面ID [nbrbs×1]

% 旧実装（変更なし）
[~, ~, idbrbs2repbrbs] = ...
  unique(secmgr.idsec2srep(secmgr.idsec2stype==PRM.BRB));

return
end