function [xlist, xup, xdw, idvartarget, idvlist] = ...
  deprecated_enumerateNeighborTf(secmgr, xvar, idvar, options)
%ENUMERATE_NEIGHBOR_TF この関数の概要をここに記述
%   詳細説明をここに記述

% 対象かチェック
nx = length(xvar);
xlist = zeros(0,length(xvar));
xup = zeros(0,nx);
xdw = zeros(0,nx);
idwfs2x = secmgr.idsec2var(secmgr.idsec2stype==PRM.WFS,1:4);

if isempty(idvar)
  return
end

if all(idwfs2x(:,4) ~= idvar)
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
tf0 = xvar(idvar);
idwfs = unique(idrepwfs2wfs(idwfs2repwfs(idwfs2x(:,4)==idvar)));
secwfs = xvar(idwfs2x(idwfs,:));
nsec = size(secwfs,1);
idvartarget = secmgr.idsec2var(idwfs,:);

% サイズアップ・ダウン断面の検索
upsec = zeros(nsec,4);
dwsec = zeros(nsec,4);
for id=1:nsec
  [upsec_, dwsec_] = secmgr.findUpDownWfsThick(...
    secwfs(id,:), 'tf', secdimlist, options);
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
% ddd = abs(upsec(:,4)-mean(upsec(:,4)));
% [~, id] = min(ddd);
% tfup = upsec(id,4);
% ---
% tfup = min(upsec(:,4));
% ---
[tfup, id] = max(upsec(:,4));
if (tfup~=tf0)
  xup = xvar;
  if (size(idvartarget,1)==1)
    xup(idvartarget(3:4)) = upsec(id,3:4);
  else
    xup = xvar; xup(idvar) = tfup;
  end
end

% TODO どの距離がいいかは要検討
% ddd = abs(dwsec(:,4)-mean(dwsec(:,4)));
% [~, id] = min(ddd);
% tfdw = dwsec(id,4);
% ---
% tfdw = max(dwsec(:,4));
% ---
[tfdw,id] = min(dwsec(:,4));
if (tfdw~=tf0)
  xdw = xvar;
  if (size(idvartarget,1)==1)
    xdw(idvartarget(3:4)) = dwsec(id,3:4);
  else
    xdw(idvar) = tfdw;
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

