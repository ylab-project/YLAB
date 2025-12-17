function [gflhead, gflbody] = ...
  write_cell_nominal_girder_force_list(com, result, icase)
%WRITE_CELL_NOMINAL_GIRDER_FORCE_LIST 名目梁の梁応力表(一次)を生成

nominal_girder = com.nominal.girder;
girder = com.member.girder;
secg = com.section.girder;
rs = result.rs0(:,:,icase);
Mc = result.Mc0(:,icase);
lm = result.lm;

gflhead = { ...
  '層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', '分割', ...
  '部材長', '左端M', '中央M', '右端M', '左端Q', '中央Q', '右端Q' ...
  '左端N', '右端N'; ...
  '', '', '', '', '', 'No.', ...
  'mm', 'kNm', 'kNm', 'kNm', 'kN', 'kN', 'kN', ...
  'kN', 'kN'};

nng = com.num.nominal_girder;
rows = cell(nng*4, size(gflhead,2));
irow = 0;

nbly = com.nbly;
nblx = com.nblx;
nstory = com.nstory;
story_id = nominal_girder.idstory;
idx = nominal_girder.idx;
idy = nominal_girder.idy;
idir = nominal_girder.idir;

for ist = nstory:-1:1
  idir_current = PRM.X;
  for iy = 1:nbly
    for ix = 1:nblx
      ing_list = find(story_id==ist & idx(:,1)==ix & ...
        idy(:,1)==iy & idir==idir_current);
      for ing = ing_list'
        add_rows(ing);
      end
    end
  end
  idir_current = PRM.Y;
  for ix = 1:nblx
    for iy = 1:nbly
      ing_list = find(story_id==ist & idx(:,1)==ix & ...
        idy(:,1)==iy & idir==idir_current);
      for ing = ing_list'
        add_rows(ing);
      end
    end
  end
end

if irow==0
  gflbody = cell(0, size(gflhead,2));
else
  gflbody = rows(1:irow,:);
end
return

  function add_rows(ing)
    idparts = nominal_girder.idmeg(ing,:);
    idparts = idparts(idparts>0);
    if isempty(idparts)
      warning('write_cell_nominal_girder_force_list: empty idmeg %d', ing);
      return
    end
    nparts = numel(idparts);
    idx_left = nominal_girder.idsub(ing,1);
    idx_right = nominal_girder.idsub(ing,2);
    if idx_left<1 || idx_left>nparts
      idx_left = 1;
    end
    if idx_right<idx_left || idx_right>nparts
      idx_right = nparts;
    end
    idx_seq = idx_left:idx_right;
    if isempty(idx_seq)
      idx_seq = 1:nparts;
    end
    for kk = 1:numel(idx_seq)
      ig = idparts(idx_seq(kk));
      im = girder.idme(ig);
      irow = irow+1;
      rows{irow,1} = nominal_girder.story_name{ing};
      rows{irow,2} = nominal_girder.frame_name{ing};
      rows{irow,3} = nominal_girder.coord_name{ing,1};
      rows{irow,4} = nominal_girder.coord_name{ing,2};
      isg = girder.idsecg(ig);
      rows{irow,5} = [secg.subindex{isg} secg.name{isg}];
      rows{irow,6} = kk;
      rows{irow,7} = sprintf('%.0f', lm(im));
      rows{irow,8} = sprintf('%.1f', -rs(im,5)*1.d-6);
      rows{irow,9} = sprintf('%.1f', Mc(ig)*1.d-6);
      rows{irow,10} = sprintf('%.1f', -rs(im,11)*1.d-6);
      rows{irow,11} = sprintf('%.1f', rs(im,3)*1.d-3);
      rows{irow,12} = '';
      rows{irow,13} = sprintf('%.1f', rs(im,9)*1.d-3);
      rows{irow,14} = sprintf('%.1f', rs(im,1)*1.d-3);
      rows{irow,15} = sprintf('%.1f', rs(im,7)*1.d-3);
    end
  end
end
