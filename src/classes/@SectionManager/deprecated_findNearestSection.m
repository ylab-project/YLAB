function secdim = deprecated_findNearestSection(secmgr, xvar, options)
% DEPRECATED: dimensionプロパティを使用する旧実装
% 新実装ではsecdimを引数として受け取る

% 計算の準備
secdim = secmgr.dimension;
nsec = size(secdim,1);
idsec2slist = zeros(nsec,2);
xvar = xvar(:)';

% 断面リストから選択
for idslist = 1:secmgr.nlist
  is_target = (secmgr.idSectionList==idslist);
  switch secmgr.getSectionType(idslist)
    case PRM.WFS
      % H形鋼
      is_target_wfs = (secmgr.idwfs2slist==idslist);
      [secwfs, ~, id] = ...
        secmgr.findNearestSectionWfs(xvar, idslist, options);
      secdim(is_target,1:5) = secwfs(is_target_wfs,:);
      idsec2slist(is_target,:) = ...
        [id.slist(is_target_wfs) id.section(is_target_wfs)];
    case PRM.HSS
      % 角形鋼管
      is_target_hss = (secmgr.idhss2slist==idslist);
      [sechss, ~, id] = ...
        secmgr.findNearestSectionHss(xvar, idslist, options);
      secdim(is_target,1:3) = sechss(is_target_hss,1:3);
      idsec2slist(is_target,:) = ...
        [id.slist(is_target_hss) id.section(is_target_hss)];
    case PRM.BRB
      % 座屈拘束ブレース
      is_target_brbs = (secmgr.idbrbs2slist==idslist);
      [secbrb, ~, id] = ...
        secmgr.findNearestSectionBrb(xvar, idslist, options);
      secdim(is_target,1:4) = secbrb(is_target_brbs,1:4);
      idsec2slist(is_target,:) = ...
        [id.slist(is_target_brbs) id.section(is_target_brbs)];
  end
end

% 結果の保存
secdim = [secdim idsec2slist];
return
end
