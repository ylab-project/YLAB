function deprecated_limit_slr_section(secmgr, member, options)
% deprecated_limit_slr_section 【非推奨】細長比制限チェック
%
% このメソッドは非推奨です。
% 代わりに limit_slr_section を使用してください。

% 定数
idphase = 999;
nsec = secmgr.nsec;
nwfs = secmgr.nwfs;
nme = secmgr.nme;
nmwfs = secmgr.nmewfs;
nlist = secmgr.nlist;
scallop = options.girder_scallop_size;

% 計算の準備
idsec2slist = secmgr.idSectionList;  % 1列版を使用
idsec2stype = secmgr.idsec2stype;
idme2sec = secmgr.idme2sec;
idsec2wfs = secmgr.idsec2wfs;

% idwfs2slist = secmgr.idwfs2slist;
idmg2m = member.girder.idme;
idmwfs2m = member.girder.idme(member.girder.section_type==PRM.WFS);
% idmwfs2s = member.property.idsec(member.property.section_type==PRM.WFS);
% idmwfs2slist = idsec2slist(idmwfs2s);
idm2mwfs = zeros(1,nme);
idm2mwfs(member.property.section_type==PRM.WFS) = 1:nmwfs;
slr = genslr(member.girder);
lbg = member.girder.stiffening_lb;
lgm_nominal = member.girder.lm_nominal;
lm_nominal(idmg2m) = lgm_nominal;
lbwfs = lbg(idmwfs2m,:);
lmwfs = lm_nominal(idmwfs2m);
slist_type = secmgr.secList.section_type;

% 断面リストごとに保有耐力横補剛を満たすH断面だけに限定
isvalid_wfs = false(1,nwfs);
for idslist = 1:nlist
  % H形鋼のみ
  if slist_type(idslist)~=PRM.WFS
    continue
  end

  % リストの抽出
  sdimlist = secmgr.getDimension(idslist, idphase);
  n = size(sdimlist,1);

  % リストの断面性能計算
  sproplist = calc_secprop(sdimlist, PRM.WFS, scallop);
  Alist = sproplist.A;
  Izlist = sproplist.Iz;
  Zylist = sproplist.Zy;
  Zpylist = sproplist.Zpy;
  Flist = secmgr.getIdSecList2F(idslist);

  % リストに対応するH形断面番号の抽出
  idphase = 999;
  isvalid = secmgr.getValidSectionOfSlist(idslist, idphase);

  % OKか判定
  isec_targets = 1:nsec;
  isec_targets = isec_targets(idsec2slist'==idslist&idsec2stype'==PRM.WFS);
  for isec=isec_targets
    imtargets = 1:nme;
    imtargets = imtargets(idme2sec'==isec);
    nmtargets = length(imtargets);
    isvalid_ = true(1,n);
    for i = 1:nmtargets
      im = imtargets(i);
      imwfs = idm2mwfs(im);
      lbi = repmat(lbwfs(imwfs,:),n,1);
      lmi = lmwfs(imwfs)*ones(n,1);
      slri.istarget = repmat(slr.istarget(imwfs,:),n,1);
      slri.lb = repmat(slr.lb(imwfs,:),n,1);
      conjbs_ = calc_girder_stiffening(...
        sdimlist, Alist, Izlist, Zylist, Zpylist, lbi, lmi, Flist, slri);
      isvalid_ = isvalid_&(conjbs_<=0)';
    end
    isvalid(idsec2wfs(isec),:) = isvalid(idsec2wfs(isec),:)&isvalid_;
  end

  % 条件を満たさないH形断面の除外
  secmgr.isValidSectionOfSlist_{idslist} = isvalid;

  % チェック結果の保存（OKのH形断面を保存）
  tmp = any(isvalid,2);
  isvalid_wfs(tmp) = tmp(tmp);
end

% 条件を満たす断面が存在しない
if ~any(isvalid_wfs)
  % エラー処理
  id = 1:nwfs; id = id(~isvalid_wfs);
  throw_err('Parse', 'limit_slr_section');
end

return
end

