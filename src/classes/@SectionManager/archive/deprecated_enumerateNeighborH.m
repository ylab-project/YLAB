function [xlist, xup, xdw, idvlist] = ...
deprecated_enumerateNeighborH(secmgr, xvar, idvar, options, delta)
%deprecated_enumerateNeighborH [非推奨] 梁せいHの近傍断面を列挙
%   この関数は非推奨です。今後は neighborSearcher.enumerateNeighborH を
%   使用してください。

if nargin==4
  delta = 150;
end

% 対象かチェック
nx = length(xvar);
xlist = zeros(0,nx);
xup = zeros(0,nx);
xdw = zeros(0,nx);
idwfs2x = secmgr.idsec2var(secmgr.idsec2stype==PRM.WFS,1:4);

if isempty(idvar)
  return
end

if all(idwfs2x(:,1)~=idvar)
  return
end

idslist = secmgr.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end

% 計算準備
nslist = length(idslist);
Hnset = secmgr.getHnominal(idslist(1));
if nslist>1
  for i=2:nslist
    Hnset_ = secmgr.getHnominal(idslist(i));
    Hnset = [Hnset(:); Hnset_(:)];
  end
end
Hnset = unique(Hnset);

% 現在値
H0 = xvar(idvar);
iddd = 1:length(Hnset);
idst0 = iddd(Hnset==H0);

% 3サイズアップ
Hmax = max(Hnset);
Hup = min(H0+delta, Hmax);
% if idst0<length(Hnset)
%   Hup = Hnset(idst0+1);
% else
%   Hup = Hmax;
% end
Hup = Hnset(Hnset>=Hup);
Hup = Hup(1);
idstup = find(Hnset==Hup);
idstup = setxor(idst0:idstup, idst0);

% 3サイズダウン
Hmin = min(Hnset);
Hdw = max(H0-delta, Hmin);
% if idst0>1
%   Hdw = Hnset(idst0-1);
% else
%   Hdw = Hmin;
% end
Hdw = Hnset(Hnset<=Hdw);
Hdw = Hdw(end);
idstdw = find(Hnset==Hdw);
idstdw = fliplr(setxor(idstdw:idst0, idst0));

% 近傍解集合
idstud = [idstup idstdw];
n = length(idstud);
nup = length(idstup);
ndw = length(idstdw);
xlist = repmat(xvar,n,1);
for i=1:n
  xlist(i,idvar) = Hnset(idstud(i));
end
xup = xlist(1:nup,:);
xdw = xlist(nup+1:end,:);
idvlist.up = 1:nup;
idvlist.dw = nup+1:nup+ndw;
return
end


