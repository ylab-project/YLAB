function [xlist, istarget, isexact] = check_restoration_thickness(...
  xlist, st, stc, C, member, matE, matF, secmgr, options)

% 計算の準備
[nlist, nx] = size(xlist);
istarget_exact = false(nlist,nx);
istarget_approx = false(nlist,nx);

% istarget_exact: 正確に必要と判断される
% istarget_approx: 近似計算から必要と判断される
if (nlist==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
do_parallel = false;

if do_parallel
  parfor id=1:nlist
    [istarget_exact(id,:), istarget_approx(id,:)] = check_thickness_individual(...
      xlist(id,:), st, stc, C, matE, matF, member, secmgr, options, id);
  end
else
  for id=1:nlist
    [istarget_exact(id,:), istarget_approx(id,:)] = check_thickness_individual(...
      xlist(id,:), st, stc, C, matE, matF, member, secmgr, options, id);
  end
end

% 計算が必要なパターンの選別
xlist = [xlist; xlist];
istarget = [istarget_exact; istarget_approx];
isexact = [true(1,nlist) false(1,nlist)];

% 近似計算で修正不要なものを省く
isnecessary = any(istarget,2)'|isexact;
xlist = xlist(isnecessary,:);
istarget = istarget(isnecessary,:);
isexact = isexact(isnecessary);

% 重複を省く
[~, idlist] = unique([xlist istarget], 'rows', 'stable');
xlist = xlist(idlist,:);
istarget = istarget(idlist,:);
isexact = isexact(idlist);
return
end

%--------------------------------------------------------------------------
function [istarget_exact, istarget_approx]  = check_thickness_individual(...
  xvar, st, stc, C, matE, matF, member, secmgr, options, id)

% 共通配列(ID変換)
idm2s = secmgr.idme2sec;
% idm2n = [member.property.idnode1 member.property.idnode2];
% idmg2m = member.girder.idme;
idmg2m = member.girder.idme(member.girder.section_type==PRM.WFS);
% idsrep2s = secmgr.idsrep2sec;
% idsrep2stype = secmgr.idsrep2stype;

% 共通配列
comp_effect = member.girder.comp_effect;
stype = secmgr.idsec2stype;
mtype = secmgr.idme2mtype;
% mstype = secmgr.idme2stype;
% gdir = member.girder.idir;
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

% 材料定数
ids2slist = SectionManager.getSectionListMapping(secdim);
idm2mat = secmgr.getIdMemberToMaterial(ids2slist);
Em = matE(idm2mat);
Fm = secmgr.extractMemberMaterialF(secdim, matF);

% 計算の準備
nx = length(xvar);
Ag = A(idmg2m);
Izg = Iz(idmg2m);
Lbg = Lb(idmg2m);
lmg = lm(idmg2m);
Fg = Fm(idmg2m);

% % 幅厚比に関する復元操作が必要な変数のチェック
% [conwtg, conwtc] = calc_wtratio(secdim, Fs, idsrep2s, idsrep2stype, options);
% idvar_wt = check_wtratio(conwtg, conwtc, secmgr);

% 細長比に関する復元操作が必要な変数のチェック
% consr = calc_slenderness_ratio(Ag, Izg, Lbg, lmg, Fg);
% idvar_slr = check_slenderness_ratio(consr, secmgr);

idvar_asr = [];
% if options.do_restration_asr && id==1
%   % 許容応力度に関する復元操作が必要な変数のチェック
%   mwfs = secdim(idm2s,:);
%   mwfs = mwfs(mstype==PRM.WFS,:);
%   [gri, grj, grc, cri, crj, gsi, gsj, csi, csj] = ...
%     allowable_stress_ratio(mwfs, st, stc, A, Iy, Iz, C, mtype, gdir, ...
%     Em, Fm, idm2n, Lb, lm, options);
%   gr = max([reshape([gri grj grc],nmg,[])],[],2);
%   gs = max([reshape([gsi; gsj],nmg,[])],[],2);
%   cr = max([reshape([cri; crj],nmc,[])],[],2);
%   cs = max([reshape([csi; csj],nmc,[])],[],2);
%   idvar_asr = check_allowable_stress_ratio(gr, gs, cr, cs, secmgr, options);
% else
%   idvar_asr = [];
% end

% 整理
istarget_exact = false(1,nx);
% istarget_exact(idvar_wt) = true;
istarget_exact(idvar_slr) = true;
istarget_approx = false(1,nx);
if (~isempty(idvar_asr))
    istarget_approx = istarget_exact;
    istarget_approx(idvar_asr) = true;
end
return
end

%--------------------------------------------------------------------------
function idvarup = check_wtratio(conwtg, conwtc, secmgr)

% 共通配列
idsrep2stype = secmgr.idsrep2stype;
idsrep2var = secmgr.idsrep2var;

% 計算の準備

% 違反制約のチェック
isviot = conwtc>0;
conwtg = reshape(conwtg,[],2);
isviotw = conwtg(:,2)>0;
isviotf = conwtg(:,1)>0;
if all([~isviot; ~isviotw; ~isviotf])
  idvarup = [];
  return
end

% 関係変数のチェック
idtup = idsrep2var(idsrep2stype==PRM.HSS,2);
idtup = unique(idtup(isviot))';
idtwup = idsrep2var(idsrep2stype==PRM.WFS,3);
idtwup = unique(idtwup(isviotw))';
idtfup = idsrep2var(idsrep2stype==PRM.WFS,4);
idtfup = unique(idtfup(isviotf))';
idvarup = unique([idtup idtwup idtfup]);
return
end

%--------------------------------------------------------------------------
function idvarup = check_slenderness_ratio(consr, secmgr)

% 共通配列
idmeg2v = secmgr.idme2var(secmgr.idme2stype==PRM.WFS,:);

% 違反制約のチェック
isviotf = consr>0;
if all(~isviotf)
  idvarup = [];
  return
end

% 関係変数のチェック
idtfup = unique(idmeg2v(isviotf,4))';
idvarup = idtfup;
return
end

%--------------------------------------------------------------------------
function idvar = check_allowable_stress_ratio(gr, gs, cr, cs, secmgr, options)

% 共通配列
idmec2v = secmgr.idme2var(secmgr.idme2stype==PRM.HSS,:);
idmeg2v = secmgr.idme2var(secmgr.idme2stype==PRM.WFS,:);

% 計算の準備
tol = options.tolRestoreSr;

% H形鋼のせん断許容応力度比制約違反からの復元対象
idgs = unique(idmeg2v(gs>tol,3))';

% H形鋼の曲げ許容応力度比制約違反からの復元対象
idgr = unique(idmeg2v(gr>tol,4));

% 角形鋼管の許容応力度比制約違反からの復元対象
idc = unique(idmec2v(cr>=tol|cs>tol,2))';

% 変数の整理
% idvar = unique([idH_up idtw_up idtf_up idt_up ]);
idvar = unique([idgs idgr idc]);
return
end
