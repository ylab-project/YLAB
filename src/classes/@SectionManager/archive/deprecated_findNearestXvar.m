function xvar = deprecated_findNearestXvar(secmgr, secdim, options)
%deprecated_findNearestXvar 断面寸法から変数値を抽出（非推奨）
%   このメソッドは非推奨です。
%   代わりに neighborSearcher.findNearestXvar を使用してください。
%
%   xvar = deprecated_findNearestXvar(secmgr, secdim, options) は、
%   断面寸法データから対応する変数値を抽出します。

% 非推奨警告
warning('SectionManager:deprecated', ...
  ['deprecated_findNearestXvar は非推奨です。' ...
   '代わりに neighborSearcher.findNearestXvar ' ...
   'を使用してください。']);

% 共通配列
idsec2stype = secmgr.idsec2stype;

% H形鋼
idrepwfs2wfs = secmgr.idrepwfs2wfs;
secwfs = secdim(idsec2stype==PRM.WFS,:);
repwfs = secwfs(idrepwfs2wfs,:);
xvar = secmgr.findNearestXvarofWfs(repwfs, [], options);

% 角形鋼管
idrephss2hss = secmgr.idrephss2hss;
sechss = secdim(idsec2stype==PRM.HSS,:);
rephss = sechss(idrephss2hss,:);
xvar = secmgr.findNearestXvarofHss(rephss, xvar, options);

% BRB
idrepbrbs2brbs = secmgr.idrepbrbs2brbs;
secbrbs = secdim(idsec2stype==PRM.BRB,:);
repbrbs = secbrbs(idrepbrbs2brbs,:);
xvar = secmgr.findNearestXvarofBrb(repbrbs, xvar, options);

return
end