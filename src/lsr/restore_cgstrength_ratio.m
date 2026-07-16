function xlist = restore_cgstrength_ratio(xlist0, secdim0, vix, viy, ...
  cgsr, idm2n, idmc2m, ~, mtype, matF, cxl, secmgr, options)

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
    xcell{id} = restore_individual(xlist0(id,:), secdim0(:,:,id), ...
      vix, viy, cgsr, idm2n, idmc2m, mtype, matF, cxl, ...
      secmgr, options);
  end
else
  for id=1:nlist0
    xcell{id} = restore_individual(xlist0(id,:), secdim0(:,:,id), ...
      vix, viy, cgsr, idm2n, idmc2m, mtype, matF, cxl, ...
      secmgr, options);
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
  cgsr, idm2n, idmc2m, mtype, matF, cxl, secmgr, options)

% 計算の準備
tol = options.tolRestoreCgr;
stype = secmgr.idsec2stype;
idm2s = secmgr.idme2sec;
idn_cgsr = cgsr.idnode;
vtype = secmgr.idvar2vtype;

% 断面性能の計算
sprop = calc_secprop(secdim, stype, [], secmgr);
Zpym = sprop.Zpy(idm2s);

% 材料定数
Fm = secmgr.extractMemberMaterialF(secdim, matF);

% 柱梁耐力比の算定
concgsr = calc_cgstrength_ratio(Zpym, vix, viy, idn_cgsr, idm2n, ...
  idmc2m, mtype, Fm, cxl, cgsr.isxdir_member, cgsr.isydir_member, ...
  cgsr.istarget);
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
xvar0 = xvar;
if options.do_aggregated_restore && ncg >= 2
  xlist = restore_aggregated_directly(xvar0, idcgset, vtype, ...
    secmgr, options);
  return
end

xlist = zeros(ncg,nx);
for icg = 1:ncg
  xvar = xvar0;

  % 柱サイズアップ
  idvc1 = idcgset(icg,1);
  xup = enumerate_cgsr_column_up(xvar, idvc1, vtype, secmgr, options);
  if ~isempty(xup)
    xvar = xup;
  end

  % 梁サイズダウン
  idvg2 = idcgset(icg,2);
  xdw = enumerate_cgsr_girder_down(xvar, idvg2, vtype, secmgr, options);
  if ~isempty(xdw)
    xvar = xdw;
  end
  xlist(icg,:) = xvar;
end

return
end

%-------------------------------------------------------------------------
function xvar_agg = restore_aggregated_directly(xvar0, idcgset, ...
  vtype, secmgr, options)
%restore_aggregated_directly - 柱梁耐力比候補を直接集約
%
%   xvar_agg = restore_aggregated_directly(xvar0, idcgset, vtype,
%     secmgr, options) は、一意な柱変数と梁変数の近傍候補を
%   xvar0 から個別に生成し、柱を max、梁を min で直接集約する。
%
%   入力引数:
%     xvar0   - 集約の基点となる設計変数 [1 x nvar]
%     idcgset - 柱変数と梁変数の組合せ [nset x 2]
%     vtype   - 各設計変数の種別 [nvar x 1]
%     secmgr  - 断面近傍探索用マネージャ
%     options - LSRオプション
%
%   出力引数:
%     xvar_agg - 直接集約した候補 [1 x nvar]

idvcset = unique(idcgset(:,1), 'stable');
idvgset = unique(idcgset(:,2), 'stable');
column_xlist = repmat(xvar0, length(idvcset), 1);
girder_xlist = repmat(xvar0, length(idvgset), 1);

for id = 1:length(idvcset)
  xup = enumerate_cgsr_column_up(xvar0, idvcset(id), vtype, ...
    secmgr, options);
  if ~isempty(xup)
    column_xlist(id,:) = xup;
  end
end
for id = 1:length(idvgset)
  xdw = enumerate_cgsr_girder_down(xvar0, idvgset(id), vtype, ...
    secmgr, options);
  if ~isempty(xdw)
    girder_xlist(id,:) = xdw;
  end
end

is_up = (vtype == PRM.HSS_D | vtype == PRM.HSS_T);
is_dn = (vtype == PRM.WFS_H | vtype == PRM.WFS_B ...
  | vtype == PRM.WFS_TW | vtype == PRM.WFS_TF);
xvar_agg = xvar0;
xvar_agg(is_up) = max(column_xlist(:,is_up), [], 1);
xvar_agg(is_dn) = min(girder_xlist(:,is_dn), [], 1);

return
end

%-------------------------------------------------------------------------
function xup = enumerate_cgsr_column_up(xvar, idvar, vtype, ...
  secmgr, options)
%enumerate_cgsr_column_up - 柱変数のアップ候補を列挙
%
%   xup = enumerate_cgsr_column_up(xvar, idvar, vtype, secmgr,
%     options) は、柱の設計変数種別に対応するアップ候補を返す。
%
%   入力引数:
%     xvar    - 基準となる設計変数 [1 x nvar]
%     idvar   - 対象設計変数番号
%     vtype   - 各設計変数の種別 [nvar x 1]
%     secmgr  - 断面近傍探索用マネージャ
%     options - LSRオプション
%
%   出力引数:
%     xup - 柱アップ候補 [0 or 1 x nvar]

xup = [];
switch vtype(idvar)
  case PRM.HSS_D
    [~, xup, ~] = secmgr.enumerateNeighborD(xvar, idvar, options);
  case PRM.HSS_T
    [~, xup, ~] = secmgr.enumerateNeighborT(xvar, idvar, options);
end

return
end

%-------------------------------------------------------------------------
function xdw = enumerate_cgsr_girder_down(xvar, idvar, vtype, ...
  secmgr, options)
%enumerate_cgsr_girder_down - 梁変数のダウン候補を列挙
%
%   xdw = enumerate_cgsr_girder_down(xvar, idvar, vtype, secmgr,
%     options) は、梁の設計変数種別に対応するダウン候補の先頭行を
%   返す。
%
%   入力引数:
%     xvar    - 基準となる設計変数 [1 x nvar]
%     idvar   - 対象設計変数番号
%     vtype   - 各設計変数の種別 [nvar x 1]
%     secmgr  - 断面近傍探索用マネージャ
%     options - LSRオプション
%
%   出力引数:
%     xdw - 梁ダウン候補 [0 or 1 x nvar]

xdw = [];
switch vtype(idvar)
  case PRM.WFS_H
    [~, ~, xdw] = secmgr.enumerateNeighborH(xvar, idvar, options);
  case PRM.WFS_B
    [~, ~, xdw] = secmgr.enumerateNeighborB(xvar, idvar, options);
  case PRM.WFS_TW
    [~, ~, xdw] = secmgr.enumerateNeighborTw(xvar, idvar, options);
  case PRM.WFS_TF
    [~, ~, xdw] = secmgr.enumerateNeighborTf(xvar, idvar, options);
end
if ~isempty(xdw)
  xdw = xdw(1,:);
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
%     idn_cgsr, idm2n, idmc2m, mtype, Fm, cxl, ...
%     cgsr.isxdir_member, cgsr.isydir_member);
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
%     [~, ~, xvarnew] = secmgr.enumerateNeighborB(xvar, ...
%       idBDset(iBD,1), options);
%     if ~isempty(xvarnew)
%       xvar = xvarnew;
%     else
%     end
%     [~, xvarnew, ~] = secmgr.enumerateNeighborD(xvar, ...
%       idBDset(iBD,2), options);
%     if ~isempty(xvarnew)
%       xvar = xvarnew;
%     end
%     xlist(icount,:) = xvar;
%   end
% end
% xlist = xlist(1:icount,:);
% xlist = unique_vertcat(xlist0, xlist);
