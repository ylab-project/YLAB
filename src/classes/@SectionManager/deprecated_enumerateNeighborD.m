function [xlist, xup, xdw, idvlist] = ...
  deprecated_enumerateNeighborD(secmgr, xvar, idvar, options)
%ENUMERATE_NEIGHBOR_B この関数の概要をここに記述
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

if all(idhss2x(:,1) ~= idvar)
  return
end

idslist = secmgr.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end

% 計算準備
nslist = length(idslist);
secdim = secmgr.getDimension(idslist(1));
Dst = secdim(:,1);
if nslist>1
  for i=2:nslist
    secdim_ = secmgr.getDimension(idslist(i));
    Dst = [Dst; secdim_(:,1)];
  end
end
Dst = unique(Dst);

% 現在値
Dcur = xvar(idvar);
iddd = 1:length(Dst);
idst_cur = iddd(Dst==Dcur);

% 1サイズアップ
idst_up = idst_cur+1;
if idst_up>length(Dst)
  idst_up = [];
end

% 1サイズダウン
idst_dw = idst_cur-1;
if idst_dw<1
  idst_dw = [];
end

% 近傍解集合
idst_ud = [idst_up idst_dw];
n = length(idst_ud);
nup = length(idst_up);
ndw = length(idst_dw);
xlist = repmat(xvar,n,1);
for i=1:n
  xlist(i,idvar) = Dst(idst_ud(i));
  % if options.do_restration
  %   [~, xlist(i,:)] = find_nearest_section_hss(xlist(i,:), secmgr, options);
  % end
end
xup = xlist(1:nup,:);
xdw = xlist(nup+1:end,:);
idvlist.up = 1:nup;
idvlist.dw = nup+1:nup+ndw;
return
end

