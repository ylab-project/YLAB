function [dbflhead, dbflbody] = ...
  write_cell_design_brace_force_list(com, result, icase)
%writeSectionProperties - Write section properties

% 定数
nb = com.nmeb;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
brace = com.member.brace;
secb = com.section.brace;
rs_all = result.rs;

% 場合分け
if icase == 1
  ilcset = 1;
  label = {'L'};
else
  ilcset = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN];
  label = {'L+Ex', 'L-Ex', 'L+Ey', 'L-Ey'};
end
nlc = length(ilcset);
maxlc = max(ilcset);

% --- 柱設計応力表 ---
dbflhead = cell(3,10);
dbflhead(1,1:10) = { ...
  '階','ﾌﾚｰﾑ','軸－軸','','符号', ...
  'ケース','タイプ','軸力','','多層'};
dbflhead(2,8:9) = {'左下り','右下り'}';
dbflhead(3,8:9) = {'kN','kN'}';

dbflbody = cell(0,size(dbflhead,2));
if nb==0
  return
end
if isempty(rs_all) || size(rs_all,3)<maxlc
  return
end
rs = rs_all(:,:,ilcset);
rows = cell(nb*nlc,size(dbflhead,2));
ibbb = 1:nb;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for idir = 1:2
    for iy = 1:nbly
      for ix = 1:nblx
        ibs = ibbb(brace.idstory==ist & ...
          brace.idx(:,1)==ix & brace.idy(:,1)==iy & brace.idir==idir);
        if isempty(ibs)
          continue
        end
        for ib = ibs
          irow = irow+1;
          rows{irow,1} = brace.floor_name{ib};
          rows{irow,2} = brace.frame_name{ib};
          rows{irow,3} = brace.coord_name{ib,1};
          rows{irow,4} = brace.coord_name{ib,2};
          isb = brace.idsecb(ib);
          rows{irow,5} = secb.name{isb};
          im = brace.idme(ib);
          for ilc=1:nlc
            if ilc>1
              irow = irow+1;
            end
            rows{irow,6} = label{ilc};
            switch brace.pair(ib)
              case {PRM.BRACE_MEMBER_PAIR_L, PRM.BRACE_MEMBER_PAIR_BOTH_L}
                pair = '／';
                rows{irow,8} = sprintf('%.0f', rs(im,1,ilc)*1.d-3);
              case {PRM.BRACE_MEMBER_PAIR_R, PRM.BRACE_MEMBER_PAIR_BOTH_R}
                pair = '＼';
                rows{irow,9} = sprintf('%.0f', rs(im,1,ilc)*1.d-3);
            end
            if ilc==1
              rows{irow,7} = pair;
            end
          end
        end
      end
    end
  end
end

if irow==0
  dbflbody = cell(0,size(dbflhead,2));
else
  dbflbody = rows(1:irow,:);
end
return
end
