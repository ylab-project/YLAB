function [head, body] = write_cell_column_force_list(com, result, icase)
%writeSectionProperties - Write section properties

%% 定数
nc = com.nmec;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
% nstory = com.nstory;
nfl = com.nfl;

%% 共通配列
column = com.member.column;
secc = com.section.column;
lm = result.lm;
rs0 = result.rs0;

%% 柱応力表(一次)
head = { ...
  '層', 'X軸', 'Y軸', '符号', '分割', '部材長', ...
  'X方向', '', '', '', '', 'Y方向', ...
  '', '', '', '', '柱頭N', '柱脚N'; ...
  '', '', '', '', 'No.', '', ...
  '柱頭M', '中央M', '柱脚M', '柱頭Q', '柱脚Q', '柱頭M', ...
  '中央M', '柱脚M', '柱頭Q', '柱脚Q', '', ''; ...
  '', '', '', '', '', 'mm',	...
  'kNm', 'kNm', 'kNm', 'kN', 'kN', 'kNm', ...
  'kNm', 'kNm', 'kN', 'kN', 'kN', 'kN'};
ncol = size(head,2);
body = cell(0,ncol);
if nc==0 || isempty(lm)
  return
end
if isempty(rs0) || size(rs0,3)<icase
  return
end
rs = rs0(:,:,icase);
body = cell(nc,ncol);
iccc = 1:nc;
irow = 0;
% for i = 1:nstory
%   ist = nstory-i+1;
for i = 1:nfl
  ifl = nfl-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        ic = iccc(column.idfloor==ifl & ...
          column.idx(:,1)==ix & column.idy(:,1)==iy & column.idz(:,1)==iz);
        if isempty(ic)
          continue
        end
        switch column.type(ic)
          case PRM.COLUMN_STANDARD
            idsub = 1;
          case PRM.COLUMN_FOR_BRACE1
            idsub = 1;
          case PRM.COLUMN_FOR_BRACE2
            idsub = 2;
        end
        irow = irow+1;
        body{irow,1} = column.floor_name{ic};
        body{irow,2} = column.coord_name{ic,1};
        body{irow,3} = column.coord_name{ic,2};
        isc = column.idsecc(ic);
        body{irow,4} = [secc.subindex{isc} secc.name{isc}];
        body{irow,5} = idsub;
        im = column.idme(ic);
        body{irow,6} = sprintf('%.0f', lm(im));
        body{irow,7} = sprintf('%.1f', -rs(im,11)*1.d-6);
        body{irow,8} = '';
        body{irow,9} = sprintf('%.1f', -rs(im,5)*1.d-6);
        body{irow,10} = sprintf('%.1f', rs(im,9)*1.d-3);
        body{irow,11} = sprintf('%.1f', rs(im,3)*1.d-3);
        body{irow,12} = sprintf('%.1f', -rs(im,12)*1.d-6);
        body{irow,13} = '';
        body{irow,14} = sprintf('%.1f', -rs(im,6)*1.d-6);
        body{irow,15} = sprintf('%.1f', -rs(im,8)*1.d-3);
        body{irow,16} = sprintf('%.1f', -rs(im,2)*1.d-3);
        body{irow,17} = sprintf('%.1f', rs(im,7)*1.d-3);
        body{irow,18} = sprintf('%.1f', rs(im,1)*1.d-3);
      end
    end
  end
end

return
end
