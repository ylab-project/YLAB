function xlist = restore_joint_bearing_strength(xlist0, ...
  member, matF, restoration, secmgr, options)
%restore_joint_bearing_strength - 仕口の保有耐力接合の復元

% 計算の準備
[nlist0, nx] = size(xlist0);
xcell = cell(nlist0,1);
mstype = member.property.section_type;
member_girder = member.girder;

% 柱σuの算定
secdim0_ = secmgr.findNearestSection( ...
  xlist0(1,:), options);
F0_ = secmgr.extractMemberMaterialF( ...
  secdim0_, matF);
Fcol_ = F0_(member.column.idme);
sigu_col = calc_sigu_col(member, Fcol_);

% 仕口の保有耐力接合の確保
if (nlist0==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
if do_parallel
  parfor id=1:nlist0
    xcell{id} = restore_individual( ...
      xlist0(id,:), member_girder, ...
      mstype, matF, restoration, ...
      secmgr, options, sigu_col);
  end
else
  for id=1:nlist0
    xcell{id} = restore_individual( ...
      xlist0(id,:), member_girder, ...
      mstype, matF, restoration, ...
      secmgr, options, sigu_col);
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

%----------------------------------------------------------
function xlist = restore_individual(xvar, ...
  member_girder, mstype, matF, ~, ...
  secmgr, options, sigu_col)

% 共通配列(ID変換)
idm2s = secmgr.idme2sec;
idmwfs2m = member_girder.idme( ...
  member_girder.section_type==PRM.WFS);
nme = length(idm2s);

% 全部材→WFS梁インデックスの変換マップ
me2wfs = zeros(nme, 1);
me2wfs(idmwfs2m) = 1:length(idmwfs2m);

% 共通配列
stype = secmgr.idsec2stype;
scallop = options.girder_scallop_size;
idsec2srep = secmgr.idsec2srep;
idsrep2sec = secmgr.idsrep2sec;

% 初期化
xlist = [];

% 断面計算
secdim = secmgr.findNearestSection( ...
  xvar, options);
msdim = secdim(idm2s,1:4);
sprop = calc_secprop( ...
  secdim, stype, scallop, secmgr);
msprop = sprop(idm2s,:);

% 部材の諸元
Zpy = msprop.Zpy;

% 材料定数
F = secmgr.extractMemberMaterialF( ...
  secdim, matF);

% 梁部材の諸元
Zpyg = Zpy(idmwfs2m);
Fg = F(idmwfs2m);

% 仕口の保有耐力接合制約の計算
msdimg = msdim(mstype==PRM.WFS,:);
conjbs = calc_joint_bearing_strength( ...
  msdimg, Zpyg, Fg, sigu_col, [], options);
if all(conjbs<=0)
  return
end

% 復元操作が必要な断面のチェック
% imtargetはWFS梁インデックス→全部材に変換
nwfs = length(conjbs);
iwfs_target = 1:nwfs;
iwfs_target = iwfs_target(conjbs>0);
ime_target = idmwfs2m(iwfs_target);
istarget = unique(idm2s(ime_target));
nstarget = length(istarget);

% 復元操作
secdim_res = secdim;
immm = 1:nme;
for i=1:nstarget
  % 該当断面
  isg = istarget(i);
  sdim_ = secdim(isg,1:4);

  % リストの断面性能計算
  idslist_ = secdim(isg, 6);
  sdimlist = secmgr.getDimension(idslist_);
  n = size(sdimlist,1);
  sdimlist = [sdimlist(:,1:5) ...
    idslist_*ones(n,1) (1:n)'];
  sproplist = calc_secprop( ...
    sdimlist, PRM.WFS, scallop);
  Zpylist = sproplist.Zpy;

  % 該当WFS梁部材ごとの許容性確認
  ims = immm(idm2s==isg);
  ims_wfs = ims(me2wfs(ims)>0);
  isok = false(n, length(ims_wfs));
  for j=1:length(ims_wfs)
    iw = me2wfs(ims_wfs(j));
    Fi = Fg(iw)*ones(n,1);
    sc_i = repmat(sigu_col(iw,:), n, 1);
    conjbs_ = calc_joint_bearing_strength( ...
      sdimlist, Zpylist, Fi, sc_i, ...
      [], options);
    isok(:,j) = conjbs_<0;
  end
  isok = all(isok,2);
  sdimlist_ = sdimlist(isok,:);
  if isempty(sdimlist_)
    continue
  end
  sdim_res = find_feasible_section( ...
    sdim_, sdimlist_);

  % 代表断面に変換
  idsrep = idsec2srep(isg);
  idsec = idsrep2sec(idsrep);
  secdim_res(idsec,:) = sdim_res;
end
xlist = secmgr.findNearestXvar( ...
  secdim_res, options);

return

  function sdimcand_ = find_feasible_section( ...
      sdim_, sdimlist_)
    ddd = pdist2(sdim_, sdimlist_(:,1:4));
    [~,idcand] = min(ddd);
    sdimcand_ = sdimlist_(idcand,:);
  end
end
