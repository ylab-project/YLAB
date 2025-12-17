function [bflhead, bflbody] = write_cell_brace_force_list(com, result, icase)
%WRITE_CELL_BRACE_FORCE_LIST 名目ブレースの力一覧を生成

nominal_brace = com.nominal.brace;
brace = com.member.brace;
secb = com.section.brace;
lm = result.lm;
rs = result.rs0(:,:,icase);

bflhead = cell(2,11);
bflhead(1,1:11) = { ...
  '階','ﾌﾚｰﾑ','軸－軸','','符号', ...
  'タイプ','左下り','','右下り','','Q'};
bflhead(2,7:10) = { ...
  '部材長','N','部材長','N'};
bflhead(3,7:11) = { ...
  'mm','kN','mm','kN','kN'};

rows = cell(com.num.nominal_brace*2, size(bflhead,2));
irow = 0;

nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;

ids_story = nominal_brace.idstory;
idx_nom = nominal_brace.idx;
idy_nom = nominal_brace.idy;
idir_nom = nominal_brace.idir;

for ist = nstory:-1:1
  % Y方向 -> X方向の順でX通りブレースを走査
  idir_current = PRM.X;
  for iy = 1:nbly
    for ix = 1:nblx
      inb_list = find(ids_story==ist & idx_nom(:,1)==ix & ...
        idy_nom(:,1)==iy & idir_nom==idir_current);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end

  % X方向 -> Y方向の順でY通りブレースを走査
  idir_current = PRM.Y;
  for ix = 1:nblx
    for iy = 1:nbly
      inb_list = find(ids_story==ist & idx_nom(:,1)==ix & ...
        idy_nom(:,1)==iy & idir_nom==idir_current);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
end

if irow==0
  bflbody = cell(0, size(bflhead,2));
else
  bflbody = rows(1:irow,:);
end
return

  function add_row(inb)
    ibij = nominal_brace.idmeb(inb,:);
    for ij=1:nnz(ibij)
      ib = ibij(ij);
      im = brace.idme(ib);
      if ij==1
        irow = irow+1;

        rows{irow,1} = nominal_brace.floor_name{inb};
        rows{irow,2} = nominal_brace.frame_name{inb,1};
        rows{irow,3} = nominal_brace.coord_name{inb,1};
        rows{irow,4} = nominal_brace.coord_name{inb,2};

        isb = brace.idsecb(ib);
        rows{irow,5} = secb.name{isb};

      end

      % ブレース配置タイプ
      switch brace.type(ib)
        case PRM.BRACE_MEMBER_TYPE_X
          if brace.pair(ib)==PRM.BRACE_MEMBER_PAIR_L
            type_label = '／';
            ipos = 1;
          elseif brace.pair(ib)==PRM.BRACE_MEMBER_PAIR_R
            type_label = '＼';
            ipos = 2;
          end
        case PRM.BRACE_MEMBER_TYPE_K_UPPER
          type_label = 'K上';
          ipos = ij;
        case PRM.BRACE_MEMBER_TYPE_K_LOWER
          ipos = ij;
          type_label = 'K下';
      end
      rows{irow,6} = type_label;

      % ブレースペアタイプ
      switch ipos
        case 1
          rows{irow,7} = sprintf('%.0f', lm(im));
          rows{irow,8} = sprintf('%.1f', rs(im,1)*1.d-3);
        case 2
          rows{irow,9} = sprintf('%.0f', lm(im));
          rows{irow,10} = sprintf('%.1f', rs(im,1)*1.d-3);
      end
    end
  end
end
