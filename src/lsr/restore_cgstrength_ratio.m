function xlist = restore_cgstrength_ratio(xlist0, secdim0, vix, viy, ...
  cgsr, idm2n, idmc2m, idm2var, idmc2sc, idmg2sg, ...
  mdir, mtype, matF, cxl, secmgr, options)

% 計算の準備
[nlist0, nx] = size(xlist0);
xcell = cell(nlist0,1);

% 柱梁耐力比の確保
if (nlist0==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
if do_parallel
  parfor id=1:nlist0
    xcell{id} = restore_individual(xlist0(id,:), secdim0(:,:,id), vix, viy, ...
      cgsr, idm2n, idmc2m, mdir, mtype, matF, cxl, secmgr, options);
  end
else
  for id=1:nlist0
    xcell{id} = restore_individual(xlist0(id,:), secdim0(:,:,id), vix, viy, ...
      cgsr, idm2n, idmc2m, mdir, mtype, matF, cxl, secmgr, options);
  end
end

% 結果の整理
nlist = 0;
xlist = zeros(1000,nx);
for id=1:nlist0
  ne = size(xcell{id},1);
  xlist(nlist+1:nlist+ne,:) = xcell{id};
  nlist = nlist+ne;
end
xlist = xlist(1:nlist,:);
xlist = unique(xlist,'rows','stable');
return
end

%-------------------------------------------------------------------------
function  xlist = restore_individual(xvar, secdim, vix, viy, ...
  cgsr, idm2n, idmc2m, mdir, mtype, matF, cxl, secmgr, options)

% 計算の準備
tol = options.tolRestoreCgr;
stype = secmgr.idsec2stype;
idm2s = secmgr.idme2sec;
idn_cgsr = cgsr.idnode;
vtype = secmgr.idvar2vtype;

% 断面性能の計算
% secdim = secmgr.findNearestSection(xvar, options);
sprop = calc_secprop(secdim, stype);
Zpym = sprop.Zpy(idm2s);

% 材料定数
Fm = secmgr.extractMemberMaterialF(secdim, matF);

% 柱梁耐力比の算定
concgsr = calc_cgstrength_ratio(Zpym, vix, viy, ...
  idn_cgsr, idm2n, idmc2m, mdir, mtype, Fm, cxl);
concgsr = reshape(concgsr,[],4);
concgsr = [max(concgsr(:,1:2),[],2) max(concgsr(:,3:4),[],2)];
is_target = concgsr>tol;
if all(~is_target)
  xlist = xvar;
  return
end

% 制約違反からの復元操作
nx = length(xvar);
ncg = length(cgsr.idnode);
idvofH_cgsr = cgsr.idvofH;
idvofB_cgsr = cgsr.idvofB;
idvoftw_cgsr = cgsr.idvoftw;
idvoftf_cgsr = cgsr.idvoftf;
idvofD_cgsr = cgsr.idvofD;
idvoft_cgsr = cgsr.idvoft;
idvgset = zeros(100,1);
idvcset = zeros(100,1);
icount = 0;
for icg=1:ncg
  for idir=1:2
    if ~is_target(icg,idir)
      continue
    end
    % 対象変数の特定
    % in = idn_cgsr(icg);
    idvofH = idvofH_cgsr{icg,idir};
    idvofB = idvofB_cgsr{icg,idir};
    idvoftw = idvoftw_cgsr{icg,idir};
    idvoftf = idvoftf_cgsr{icg,idir};
    idvofD = idvofD_cgsr{icg};
    idvoft = idvoft_cgsr{icg};
    idvc = [idvofD; idvoft];
    idvg = [idvofH; idvofB; idvoftw; idvoftf];
    [idvcset_, idvgset_] = meshgrid(idvc,idvg);
    ne = numel(idvcset_);
    idvcset(icount+1:icount+ne) = idvcset_(:);
    idvgset(icount+1:icount+ne) = idvgset_(:);
    icount = icount+ne;
  end
end
idcgset = unique([idvcset(1:icount) idvgset(1:icount)], 'rows', 'stable');
ncg = size(idcgset,1);
xlist = zeros(ncg,nx);
xvar0 = xvar;
for icg = 1:ncg
  xvar = xvar0;
  xup = []; xdw = [];

  % 柱サイズアップ
  switch vtype(idcgset(icg,1))
    case PRM.HSS_D
      [~, xup, ~] = secmgr.enumerateNeighborD(xvar, idcgset(icg,1), options);
    case PRM.HSS_T
      [~, xup, ~] = secmgr.enumerateNeighborT(xvar, idcgset(icg,1), options);
  end
  if ~isempty(xup)
    xvar = xup;
    % xvar(xvar0~=xup) = xup(xvar0~=xup);
  end
      
  % 梁サイズダウン
  switch vtype(idcgset(icg,2))
    case PRM.WFS_H
      [~, ~, xdw] = secmgr.enumerateNeighborH(xvar, idcgset(icg,2), options);
    case PRM.WFS_B
      [~, ~, xdw] = secmgr.enumerateNeighborB(xvar, idcgset(icg,2), options);
    case PRM.WFS_TW
      [~, ~, xdw] = secmgr.enumerateNeighborTw(xvar, idcgset(icg,2), options);
    case PRM.WFS_TF
      [~, ~, xdw] = secmgr.enumerateNeighborTf(xvar, idcgset(icg,2), options);
  end
  if ~isempty(xdw)
    xdw = xdw(1,:);
    xvar = xdw;
    % xvar(xvar0~=xdw) = xdw(xvar0~=xdw);
  end
  xlist(icg,:) = xvar;
end
return
end

% % 計算の準備
% ncg = length(idn_cgsr);
% [nlist,m] = size(xlist0);
% xlist = zeros(1000,m);
% icount = 0;
% for ilist = 1:nlist
%   % 断面性能の計算
%   xvar = xlist0(ilist,:);
%   secdim = secmgr.findNearestSection(xvar, options);
%   xvar = secmgr.findNearestXvar(secdim, options);
%   sprop = calc_secprop(secdim, stype);
%   Zpym = sprop.Zpy(idm2s);
%
%   % 柱梁耐力比の算定
%   concgsr = calc_cgstrength_ratio(Zpym, vix, viy, ...
%     idn_cgsr, idm2n, idmc2m, medir, mtype, Fm);
%   concgsr = reshape(concgsr,[],2);
%   is_target = concgsr>tol;
%   if all(~is_target)
%
%   end
%
%   % 制約違反からの復元操作
%   idvBset = [];
%   idvDset = [];
%   for icg=1:ncg
%     for idir=1:2
%       if ~is_target(icg,idir)
%         continue
%       end
%       % 対象変数の特定
%       in = idn_cgsr(icg);
%       idvofH = idvofH_cgsr{icg,idir};
%       idvofB = idvofB_cgsr{icg,idir};
%       idvofD = idvofD_cgsr{icg};
%       [idvBset_, idvDset_] = meshgrid(idvofB,idvofD);
%       idvBset = [idvBset; idvBset_'];
%       idvDset = [idvDset; idvDset_'];
%     end
%   end
%   idBDset = unique([idvBset idvDset],'rows','stable');
%   % xvar0 = xvar;
%   nBD = size(idBDset,1);
%   for iBD = 1:nBD
%     icount = icount+1;
%     [~, ~, xvarnew] = secmgr.enumerateNeighborB(xvar, idBDset(iBD,1), options);
%     if ~isempty(xvarnew)
%       xvar = xvarnew;
%     else
%     end
%     [~, xvarnew, ~] = secmgr.enumerateNeighborD(xvar, idBDset(iBD,2), options);
%     if ~isempty(xvarnew)
%       xvar = xvarnew;
%     end
%     xlist(icount,:) = xvar;
%   end
% end
% xlist = xlist(1:icount,:);
% xlist = unique_vertcat(xlist0, xlist);
