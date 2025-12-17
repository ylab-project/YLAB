function istarget = check_restoration_height(...
  xlist, st, stc, C, member, Es, Fs, secmgr, options)

% 計算の準備
[nlist, nx] = size(xlist);
istarget = false(nlist,nx);
if (nlist==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end

if do_parallel
  parfor id=1:nlist
    istarget(id,:) = check_each(...
      xlist(id,:), st, stc, C, Es, Fs, member, secmgr, options);
  end
else
  for id=1:nlist
    istarget(id,:) = check_each(...
      xlist(id,:), st, stc, C, Es, Fs, member, secmgr, options);
  end
end
return
end

%--------------------------------------------------------------------------
function istarget = check_each(...
  xvar, st, stc, C, Es, Fs, member, secmgr, options)

% 共通配列(ID変換)
idm2s = secmgr.idme2sec;
idm2n = [member.property.idnode1 member.property.idnode2];
% idmg2m = member.girder.idme;
% idsrep2s = secmgr.idsrep2sec;
% idsrep2stype = secmgr.idsrep2stype;

% 共通配列
comp_effect = member.girder.comp_effect;
stype = secmgr.idsec2stype;
mtype = secmgr.idme2mtype;
mstype = secmgr.idme2stype;
gdir = member.girder.idir;
Lb = member.girder.Lb;
lm = member.property.lm;

% 共通定数
scallop = options.girder_scallop_size;
nmc = sum(member.property.type==PRM.COLUMN);
nmg = sum(member.property.type==PRM.GIRDER);

% 断面計算
secdim = secmgr.findNearestSection(xvar, options);
sprop = calc_secprop(secdim, stype, scallop);
mprop = sprop(idm2s,:);
A = mprop.A;
Iy = mprop.Iy;
phiI = ones(nmg,1);
phiI(comp_effect==1) = 1.3;
phiI(comp_effect==2) = 1.5;
Iy(mtype==PRM.GIRDER) = Iy(mtype==PRM.GIRDER).*phiI;
Iz = mprop.Iz;

% 計算の準備
% nx = length(xvar);
% Ag = A(idmg2m);
% Izg = Iz(idmg2m);
% Lbg = Lb(idmg2m);
% lmg = lm(idmg2m);
Em = Es(idm2s);
Fm = Fs(idm2s);
% Fg = Fm(idmg2m);

% 許容応力度に関する復元操作が必要な変数のチェック
mwfs = secdim(idm2s,:);
mwfs = mwfs(mstype==PRM.WFS,:);
% [gri, grj, grc, cri, crj, gsi, gsj, csi, csj] = ...
[gri, grj, grc] = ...
  allowable_stress_ratio(mwfs, st, stc, A, Iy, Iz, C, mtype, gdir, ...
  Em, Fm, idm2n, Lb, lm, options);
gr = max([reshape([gri grj grc],nmg,[])],[],2);
% gs = max([reshape([gsi; gsj],nmg,[])],[],2);
% cr = max([reshape([cri; crj],nmc,[])],[],2);
% cs = max([reshape([csi; csj],nmc,[])],[],2);
istarget = check_allowable_stress_ratio(gr, secmgr, options);
return
end

%--------------------------------------------------------------------------
function istarget = check_allowable_stress_ratio(gr, secmgr, options)

% 共通配列
nx = secmgr.nxvar;
% idmec2v = secmgr.idme2var(secmgr.idme2stype==PRM.HSS,:);
idmeg2v = secmgr.idme2var(secmgr.idme2stype==PRM.WFS,:);

% 計算の準備
tol = options.tolRestoreSr;

% % H形鋼のせん断許容応力度比制約違反からの復元対象
% idgs = unique(idmeg2v(gs>tol,3))';
% 
% H形鋼の曲げ許容応力度比制約違反からの復元対象
idgr = unique(idmeg2v(gr>tol,[1 4]));

% % 角形鋼管の許容応力度比制約違反からの復元対象
% idc = unique(idmec2v(cr>=tol|cs>tol,2))';
% 
% 変数の整理
% idvar = unique([idH_up idtw_up idtf_up idt_up ]);
% idvar = unique([idgs idgr idc]);
% idvar = unique([idgs idgr idc]);
idvar = idgr;
istarget = false(1,nx);
istarget(idvar) = true;
return
end
