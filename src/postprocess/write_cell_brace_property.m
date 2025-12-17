function [bphead, bpbody] = write_cell_brace_property(com, result)
%write_cell_brace_property ブレース断面セル配列を生成

% 定数・共通配列
nb = com.nmeb;
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
brace = com.member.brace;
secb = com.section.brace;
story = com.story;
msprop = result.msprop;
Em = msprop.E;
lm = result.lm;

% ヘッダー行
bphead = cell(3,20);
bphead(1,1:5) = {'階', 'ﾌﾚｰﾑ', '軸－軸', '', '符号'};
bphead(1,6:10) = {'タイプ','E', 'Ao', '左下り',''};
bphead(1,15) = {'右下り'};
bphead(2,9:10) = {'φA','A'};
bphead(2,11:15) = {'引圧','λe','座屈長','部材長','φA'};
bphead(2,16:20) = {'A','引圧','λe','座屈長','部材長'};
bphead(3,6:10) = {'','kN/mm2','cm2','','cm2'};
bphead(3,11:15) = {'','','mm','mm',''};
bphead(3,16) = {'cm2'};

% 本体作成
bpbody = cell(nb,20);
irow = 0;
ibbb = 1:nb;
for i=1:nstory
  ist = nstory-i+1;
  for idir = 1:2
    for iy = 1:nbly
      for ix = 1:nblx
        ibs = ibbb(brace.idstory==ist & ...
          brace.idx(:,1)==ix & brace.idy(:,1)==iy & brace.idir==idir);
        if isempty(ibs)
          continue
        end
        write_bpbody();
      end
    end
  end
end

return

  function write_bpbody()
    for ib = ibs
      irow = irow+1;
      floor_name = story.floor_name{ist};
      bpbody{irow,1} = floor_name;
      bpbody{irow,2} = brace.frame_name{ib};
      bpbody(irow,3:4) = brace.coord_name(ib,1:2);
      idsb = brace.idsecb(ib);
      bpbody{irow,5} = secb.name{idsb};
      switch brace.pair(ib)
        case {PRM.BRACE_MEMBER_PAIR_L, PRM.BRACE_MEMBER_PAIR_BOTH_L}
          pair = '／';
        case {PRM.BRACE_MEMBER_PAIR_R, PRM.BRACE_MEMBER_PAIR_BOTH_R}
          pair = '＼';
        otherwise
          pair = '';
      end
      bpbody{irow,6} = pair;
      idm = brace.idme(ib);
      bpbody{irow,7} = Em(idm)*1.d-3;
      bpbody{irow,8} = sprintf('%.1f', msprop.A(idm)*1.d-2);

      if brace.pair(ib)==PRM.BRACE_MEMBER_PAIR_L
        bpbody{irow,9} = sprintf('%.3f', 1);
        bpbody{irow,10} = sprintf('%.1f', msprop.A(idm)*1.d-2);
        bpbody{irow,11} = '引圧';
        bpbody{irow,13} = sprintf('%.0f', lm(idm));
        bpbody{irow,14} = sprintf('%.0f', lm(idm));
      end

      if brace.pair(ib)==PRM.BRACE_MEMBER_PAIR_R
        bpbody{irow,15} = sprintf('%.3f', 1);
        bpbody{irow,16} = sprintf('%.1f', msprop.A(idm)*1.d-2);
        bpbody{irow,17} = '引圧';
        bpbody{irow,19} = sprintf('%.0f', lm(idm));
        bpbody{irow,20} = sprintf('%.0f', lm(idm));
      end
    end
  end
end

