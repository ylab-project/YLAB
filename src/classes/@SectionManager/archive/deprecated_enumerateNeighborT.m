function [xlist, xup, xdw, idvartarget, idvlist] = ...
  deprecated_enumerateNeighborT(secmgr, xvar, idvar, options)
%ENUMERATE_NEIGHBOR_TF この関数の概要をここに記述
%   詳細説明をここに記述

% 対象かチェック
nx = length(xvar);
xlist = zeros(0,nx);
xup = zeros(0,nx);
xdw = zeros(0,nx);
idhss2x = secmgr.idsec2var(secmgr.idsec2stype==PRM.HSS,1:2);

if isempty(idvar)
  return
end

if all(idhss2x(:,2) ~= idvar)
  return
end

idslist = secmgr.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end

% 計算準備
idhss2rephss = secmgr.idhss2rephss;
idrephss2hss = secmgr.idrephss2hss;
secdimlist = secmgr.getDimension(idslist);

% 現在値
t0 = xvar(idvar);
idhss = unique(idrephss2hss(idhss2rephss(idhss2x(:,2)==idvar)));
sechss = xvar(idhss2x(idhss,:));
nsec = size(sechss,1);
idvartarget = secmgr.idsec2var(idhss,:);

% サイズアップ・ダウン断面の検索
upsec = zeros(nsec,2);
dwsec = zeros(nsec,2);
for id=1:nsec
  [upsec_, dwsec_] = secmgr.findUpDownHssThick(...
    sechss(id,:), secdimlist, options);
  if isempty(upsec_)
    upsec_ = sechss(id,1:2);
  end
  upsec(id,:) = upsec_(1:2);
  if isempty(dwsec_)
    dwsec_ = sechss(id,1:2);
  end
  dwsec(id,:) = dwsec_(1:2);
end

% 近傍解集合
% TODO どの距離がいいかは要検討
% ddd = abs(upsec(:,2)-mean(upsec(:,2)));
% [~, id] = min(ddd);
% tup = upsec(id,2);
%---
% tup = min(upsec(:,2));
%---
tup = max(upsec(:,2));
if (tup~=t0)
  xup = xvar; xup(idvar) = tup;
end

% TODO どの距離がいいかは要検討
% ddd = abs(dwsec(:,2)-mean(dwsec(:,2)));
% [~, id] = min(ddd);
% tdw = dwsec(id,2);
%---
% tdw = max(dwsec(:,2));
%---
tdw = min(dwsec(:,2));
if (tdw~=t0)
  xdw = xvar; xdw(idvar) = tdw;
end

% 近傍解集合の整理
nup = size(xup,1);
ndw = size(xdw,1);
nnn = [ones(1,nup) -ones(1,ndw)];
[xlist, ia] = unique([xup; xdw],'rows','stable');
nnn = nnn(ia);
iddd = 1:size(xlist,1);
idvlist.up = iddd(nnn>0);
idvlist.dw = iddd(nnn<0);
return
end

