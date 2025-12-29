function [xlist, xup, xdw, idvlist] = ...
  deprecated_enumerateNeighborB(secmgr, xvar, idvar, options)
%ENUMERATE_NEIGHBOR_B この関数の概要をここに記述
%   詳細説明をここに記述

% 対象かチェック
nx = length(xvar);
xlist = zeros(0,nx);
xup = zeros(0,nx);
xdw = zeros(0,nx);
idwfs2x = secmgr.idsec2var(secmgr.idsec2stype==PRM.WFS,1:4);

if isempty(idvar)
  return
end

if all(idwfs2x(:,2)~=idvar)
  return
end

% 計算準備
idslist = secmgr.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end
Bnset = secmgr.getBnominal(idslist);

% 現在値
B0 = xvar(idvar);
iddd = 1:length(Bnset);
idst0 = iddd(Bnset==B0);

% 1サイズアップ
idstup = idst0+1;
if idstup>length(Bnset)
  idstup = [];
end

% 1サイズダウン
idstdw = idst0-1;
if idstdw<1
  idstdw = [];
end

% 近傍解集合
idstud = [idstup idstdw];
n = length(idstud);
nup = length(idstup);
ndw = length(idstdw);
xlist = repmat(xvar,n,1);
for i=1:n
  xlist(i,idvar) = Bnset(idstud(i));
end
xup = xlist(1:nup,:);
xdw = xlist(nup+1:end,:);
idvlist.up = 1:nup;
idvlist.dw = nup+1:nup+ndw;
return
end

