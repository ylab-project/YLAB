function xlist = restore_girder_slratio(...
  xlist0, member, matF, restoration, secmgr, options)

% 計算の準備
[nlist0, nx] = size(xlist0);
xcell = cell(nlist0,1);
mstype = member.property.section_type;
member_girder = member.girder;
% slr = restoration.slr;
% igthrough = member.girder_through.idmeg;
% idmg2m = member.girder.idme;
% gjoint = member.girder.joint;
% mejoint = PRM.FIX*ones(size(member.property,1),4);
% mejoint(idmg2m,:) = gjoint;

% 細長比（保有耐力横補剛）の確保
if (nlist0==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
if do_parallel
  parfor id=1:nlist0
    xcell{id} = restore_individual(...
      xlist0(id,:), member_girder, mstype, matF, ...
      restoration, secmgr, options);
  end
else
  for id=1:nlist0
    xcell{id} = restore_individual(...
      xlist0(id,:), member_girder, mstype, matF, ...
      restoration, secmgr, options);
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

%--------------------------------------------------------------------------
function xlist = restore_individual(...
  xvar, member_girder, mstype, matF, restoration, secmgr, options)

% 共通配列(ID変換)
idm2s = secmgr.idme2sec;
% idmg2m = member_girder.idme;
idmwfs2m = member_girder.idme(member_girder.section_type==PRM.WFS);
nme = length(idm2s);

% 共通配列
stype = secmgr.idsec2stype;
scallop = options.girder_scallop_size;
idsec2srep = secmgr.idsec2srep;
idsrep2sec = secmgr.idsrep2sec;

% 初期化
xlist = [];

% 断面計算
secdim = secmgr.findNearestSection(xvar, options);
msdim = secdim(idm2s,1:4);
sprop = calc_secprop(secdim, stype, scallop);
msprop = sprop(idm2s,:);

% 部材の諸元
A = msprop.A;
Iz = msprop.Iz;
Zy = msprop.Zy;
Zpy = msprop.Zpy;
% HAf = msdim(:,1)./(msdim(:,2).*msdim(:,4));

% 材料定数
F = secmgr.extractMemberMaterialF(secdim, matF);

% 梁部材の諸元
Ag = A(idmwfs2m);
Izg = Iz(idmwfs2m);
Zyg = Zy(idmwfs2m);
Zpyg = Zpy(idmwfs2m);
Fg = F(idmwfs2m);

% % 床による梁剛性の考慮
% Iyg = calc_composite_girder_Iy(...
%   member_girder, msdim, msprop, idmg2m, options);

% 細長比制約の計算
lbg = restoration.lbwfs;
lmg = restoration.lmwfs;
slr = restoration.slr;
msdimg = msdim(mstype==PRM.WFS,:);
conslr = calc_girder_stiffening(...
  msdimg, Ag, Izg, Zyg, Zpyg, lbg, lmg, Fg, slr);
conslr = conslr+options.coptions.alfa_slenderness_ratio;
if conslr>0
  return
end

% 復元操作が必要な断面のチェック
nwfs = length(conslr);
imtarget = 1:nwfs; imtarget = imtarget(conslr>0);
istarget = unique(idm2s(imtarget));
nstarget = length(istarget);

% 細長比に関する復元操作
% slr_target = slr.istarget(idmwfs2m,:);
% slr_lb = slr.lb(idmwfs2m,:);
slr_target = slr.istarget;
slr_lb = slr.lb;
secdim_res = secdim;
immm = 1:nme;
for i=1:nstarget
  % 該当断面
  isg = istarget(i);
  sdim_ = secdim(isg,1:4);

  % リストの断面性能計算
  idslist_ = ids2slist(isg,1);
  sdimlist = secmgr.getDimension(idslist_);
  n = size(sdimlist,1);
  sdimlist = [sdimlist(:,1:5) idslist_*ones(n,1) (1:n)'];
  sproplist = calc_secprop(sdimlist, PRM.WFS, scallop);
  Alist = sproplist.A;
  Izlist = sproplist.Iz;
  Zylist = sproplist.Zy;
  Zpylist = sproplist.Zpy;

  % 該当部材ごとの許容性確認
  ims = immm(idm2s==isg);
  isok = false(n,length(ims));
  for j=1:length(ims)
    iwfs = ims(j);
    lbi = repmat(lbg(iwfs,:),n,1);
    lmi = lmg(iwfs)*ones(n,1);
    Fi = Fg(iwfs)*ones(n,1);
    slri.istarget = repmat(slr_target(iwfs,:),n,1);
    slri.lb = repmat(slr_lb(iwfs,:),n,1);
    consr_ = calc_girder_stiffening(...
      sdimlist, Alist, Izlist, Zylist, Zpylist, lbi, lmi, Fi, slri);
    isok(:,j) = consr_<0;
  end
  isok = all(isok,2);
  sdimlist_ = sdimlist(isok,:);
  sdim_res = find_feasible_section(sdim_, sdimlist_);

  % 代表断面に変換
  idsrep = idsec2srep(isg);
  idsec = idsrep2sec(idsrep);
  secdim_res(idsec,:) = sdim_res;
end
xlist = secmgr.findNearestXvar(secdim_res, options);
return
  function sdimcand_ = find_feasible_section(sdim_, sdimlist_)
    ddd = pdist2(sdim_, sdimlist_(:,1:4));
    [~,idcand] = min(ddd);
    sdimcand_ = sdimlist_(idcand,:);
  end
end


