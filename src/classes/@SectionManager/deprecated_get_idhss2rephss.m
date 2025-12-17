function idhss2rephss = deprecated_get_idhss2rephss(secmgr)
%deprecated_get_idhss2rephss HSS断面の代表断面ID取得（旧実装）
%   idhss2rephss = deprecated_get_idhss2rephss(secmgr) は、
%   HSS断面IDを代表HSS断面IDに変換します。
%
%   この関数は非推奨です。get.idhss2rephssを使用してください。
%
%   出力引数:
%     idhss2rephss - HSS断面→代表HSS断面ID [nhss×1]

% 旧実装（変更なし）
[~, ~, idhss2rephss] = ...
  unique(secmgr.idsec2srep(secmgr.idsec2stype==PRM.HSS));

return
end