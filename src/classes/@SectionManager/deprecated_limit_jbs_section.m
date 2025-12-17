function deprecated_limit_jbs_section(secmgr, isjbs, options)
% deprecated_limit_jbs_section 【非推奨】保有耐力接合(JBS)制限チェック
%
% このメソッドは非推奨です。
% 代わりに limit_jbs_section を使用してください。

% 定数
idphase = 999;
nsec = secmgr.nsec;
% nme = size(member.property,1);
nwfs = secmgr.nwfs;
nlist = secmgr.nlist;
scallop = options.girder_scallop_size;

% 計算の準備
idsec2slist = secmgr.idSectionList;  % 1列版を使用
idsec2stype = secmgr.idsec2stype;
idsec2wfs = secmgr.idsec2wfs;
slist_type = secmgr.secList.section_type;

% 断面リストごとに保有耐力接合(仕口)を満たす断面だけに限定
isvalid_wfs = false(1,nwfs);
for idslist = 1:nlist
  % H形鋼のみ
  if slist_type(idslist)~=PRM.WFS
    continue
  end

  % リストの抽出
  sdimlist = secmgr.getDimension(idslist, idphase);
  % n = size(sdimlist,1);

  % リストの断面性能計算
  sproplist = calc_secprop(sdimlist, PRM.WFS, scallop);
  Zpylist = sproplist.Zpy;
  Flist = secmgr.getIdSecList2F(idslist);

  % リストに対応する断面の抽出と判定
  isvalid = secmgr.isValidSectionOfSlist_{idslist};
  isec_targets = 1:nsec;
  isec_targets = isec_targets(idsec2slist'==idslist&idsec2stype'==PRM.WFS);

  % OKか判定
  conjbs_ = calc_joint_bearing_strength(...
    sdimlist, Zpylist, Flist, [], options);
  isvalid_ = (conjbs_<0)';
  for isec=isec_targets
    isvalid(idsec2wfs(isec),:) = isvalid(idsec2wfs(isec),:)&isvalid_;
  end

  % 条件を満たさないH形断面の除外
  secmgr.isValidSectionOfSlist_{idslist} = isvalid;

  % チェック結果の保存（OKのH形断面を保存）
  tmp = any(isvalid,2);
  isvalid_wfs(tmp) = tmp(tmp);
end

% 検討対象外の部材はOKとする
isvalid_wfs(~any(isjbs,2)) = true;

% 条件を満たす断面が存在しない
if ~any(isvalid_wfs)
  % エラー処理
  id = 1:nwfs; id = id(~isvalid_wfs);
  throw_err('Parse', 'limit_jbs_section');
end

return
end

