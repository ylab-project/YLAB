function congapstd = calc_section_list_gap(secdim, secmgr)

% 定数
nsec = secmgr.nsec;

% 計算の準備
secdim = secdim(secmgr.idsrep2sec,:);
% stype = secmgr.idsrep2stype;
idsrep2slist = secmgr.idSectionList(secmgr.idsrep2sec);
congapstd = zeros(nsec,1);
isss = 1:nsec;

for idlist = 1:secmgr.nlist
  secdimlist = secmgr.getDimension(idlist);
  idtarget = isss(idsrep2slist==idlist);
  % ntarget = length(idtarget);
  switch secmgr.getSectionType(idlist)
    case PRM.WFS
      % H形断面の距離
      for id = idtarget
        distance = sum(((secdimlist(:,1:4)-secdim(id,1:4))...
          ./secdim(id,1:4)).^2,2);
        congapstd(id) = min(distance)/4;
      end

    case PRM.HSS
      % Box断面の距離
      for id = idtarget
        distance = sum(((secdimlist(:,1:2)-secdim(id,1:2))...
          ./secdim(id,1:2)).^2,2);
        congapstd(id) = min(distance)/2;
      end
  end
end

% 結果の整理
congapstd = sqrt(congapstd);
end
