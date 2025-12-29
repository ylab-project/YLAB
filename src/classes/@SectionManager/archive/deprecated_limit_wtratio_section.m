function deprecated_limit_wtratio_section(secmgr, section, options)
% deprecated_limit_wtratio_section 【非推奨】幅厚比制限チェック
%
% このメソッドは非推奨です。
% 代わりに limit_wtratio_section を使用してください。

% 定数
idphase = 999;
nwfs = secmgr.nwfs;

% 計算の準備
% idsec2slist = secmgr.idsec2slist;
% idwfs2sec = secmgr.idwfs2sec;
% idwfs2slist = secmgr.idwfs2slist;
girder_rank = section.girder.rank(section.girder.type==PRM.WFS);
girder_idslist = section.girder.id_section_list(section.girder.type==PRM.WFS);

% 断面リストごとに幅厚比を満たす断面だけに限定
for idslist = 1:secmgr.nlist
  % リストの抽出
  sdimlist = secmgr.getDimension(idslist, idphase);
  n = size(sdimlist,1);

  % リストに対応する断面番号の抽出
  idphase = 999;
  isvalid = secmgr.getValidSectionOfSlist(idslist, idphase);

  % 断面種別ごと
  switch secmgr.secList.section_type(idslist)
    case PRM.WFS
      % --- WFS ---
      % idmat = secmgr.getIdSecList2Material(idslist);
      isSN = secmgr.getIdSecList2isSN(idslist);
      isSNH = isSN&options.consider_SNH_WTRATIO;
      
      F = secmgr.getIdSecList2F(idslist);
      H = sdimlist(:,1);
      B = sdimlist(:,2);
      tw = sdimlist(:,3);
      tf = sdimlist(:,4);

      conwt = ones(n,nwfs);
      for irank=1:4
        [~, ~, conwt_] = wtratioH(H, B, tw, tf, F, irank, isSNH);
        for i=1:nwfs
          if girder_rank(i)==irank&&girder_idslist(i)==idslist
            conwt(:,i) = conwt_;
          end
        end
      end
      isvalid_ = conwt'<=0;
      secmgr.isValidSectionOfSlist_{idslist} = isvalid&isvalid_;

    case PRM.HSS
      % --- HSS ---
      F = secmgr.getIdSecList2F(idslist);
      D = sdimlist(:,1);
      t = sdimlist(:,2);
      % r = dimension(:,3);

      % 幅厚比を満たさない断面の除外
      [~, conwt] = wtratioBox(D, t, F, options.coptions.rank_column);
      isvalid_ = conwt'<=0;
      secmgr.isValidSectionOfSlist_{idslist} = isvalid&isvalid_;
  end
end

return
end

