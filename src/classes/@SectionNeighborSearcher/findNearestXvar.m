function xvar = findNearestXvar(obj, secdim, options)
%findNearestXvar 断面寸法から変数値を抽出
%   xvar = findNearestXvar(obj, secdim, options) は、
%   断面寸法データから対応する変数値を抽出します。
%
%   入力引数:
%     secdim  - 断面寸法データ [nsec×7]
%     options - オプション構造体
%
%   出力引数:
%     xvar    - 変数値ベクトル [1×nxvar]

% 共通配列
idsec2stype = obj.idMapper_.idsec2stype;

% H形鋼
idrepwfs2wfs = obj.idMapper_.idrepwfs2wfs;
secwfs = secdim(idsec2stype == PRM.WFS, :);
repwfs = secwfs(idrepwfs2wfs, :);
xvar = obj.findNearestXvarofWfs(repwfs, [], options);

% 角形鋼管
idrephss2hss = obj.idMapper_.idrephss2hss;
sechss = secdim(idsec2stype == PRM.HSS, :);
rephss = sechss(idrephss2hss, :);
xvar = obj.findNearestXvarofHss(rephss, xvar, options);

% BRB
idrepbrbs2brbs = obj.idMapper_.idrepbrbs2brbs;
secbrbs = secdim(idsec2stype == PRM.BRB, :);
repbrbs = secbrbs(idrepbrbs2brbs, :);
xvar = obj.findNearestXvarofBrb(repbrbs, xvar, options);

% HSR（円形鋼管）
idrephsr2hsr = obj.idMapper_.idrephsr2hsr;
sechsr = secdim(idsec2stype == PRM.HSR, :);
rephsr = sechsr(idrephsr2hsr, :);
xvar = obj.findNearestXvarofHsr(rephsr, xvar, options);

return
end