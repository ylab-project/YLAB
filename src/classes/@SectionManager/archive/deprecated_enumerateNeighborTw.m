function [xlist, xup, xdw, idvartarget, idvlist] = ...
  deprecated_enumerateNeighborTw(secmgr, xvar, idvar, options)
%ENUMERATE_NEIGHBOR_HTW この関数の概要をここに記述
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

if all(idwfs2x(:,3) ~= idvar)
  return
end

idslist = secmgr.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end

% 計算準備
idwfs2repwfs = secmgr.idwfs2repwfs;
idrepwfs2wfs = secmgr.idrepwfs2wfs;
secdimlist = secmgr.getDimension(idslist);

% 現在値
tw0 = xvar(idvar);
idwfs = unique(idrepwfs2wfs(idwfs2repwfs(idwfs2x(:,3)==idvar)));
secwfs = xvar(idwfs2x(idwfs,:));
nsec = size(secwfs,1);
idvartarget = secmgr.idsec2var(idwfs,:);

% サイズアップ・ダウン断面の検索
upsec = zeros(nsec,4);
dwsec = zeros(nsec,4);
for id=1:nsec
  [upsec_, dwsec_] = secmgr.findUpDownWfsThick(...
    secwfs(id,:), 'tw', secdimlist, options);
  if isempty(upsec_)
    upsec_ = secwfs(id,1:4);
  end
  upsec(id,:) = upsec_(1:4);
  if isempty(dwsec_)
    dwsec_ = secwfs(id,1:4);
  end
  dwsec(id,:) = dwsec_(1:4);
end

% 近傍解集合
% TODO どの距離がいいかは要検討
% ddd = abs(upsec(:,3)-mean(upsec(:,3)));
% [~, id] = min(ddd);
% twup = upsec(id,3);
%---
% twup = min(upsec(:,3));
%---
[twup, id] = max(upsec(:,3));
if (twup~=tw0)
  xup = xvar;
  if (size(idvartarget,1)==1)
    xup(idvartarget(3:4)) = upsec(id,3:4);
  else
    xup(idvar) = twup;
  end
end

% TODO どの距離がいいかは要検討
% ddd = abs(dwsec(:,3)-mean(dwsec(:,3)));
% [~, id] = min(ddd);
% twdw = dwsec(id,3);
%---
% twdw = max(dwsec(:,3));
%---
[twdw, id] = min(dwsec(:,3));
if (twdw~=tw0)
  xdw = xvar;
  if (size(idvartarget,1)==1)
    xdw(idvartarget(3:4)) = dwsec(id,3:4);
  else
    xdw(idvar) = twdw;
  end
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
