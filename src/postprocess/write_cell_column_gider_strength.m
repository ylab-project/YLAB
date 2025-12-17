function sdrcell = write_cell_column_gider_strength(com, result, icase)

% 共通定数
ncgsr = com.ncgsr;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nstory = com.nstory;
nnode = com.nnode;

% 共通配列
idcg2n = com.cgsr.idnode;
node = com.node;
cgsr = result.cgsr;
% floor_height = com.floor.height;
% floor_name = com.floor.name;
% dx = result.drift.dx;
% dy = result.drift.dy;
% angle = result.drift.angle;

% ---  柱梁耐力比 ---
head = cell(4,13);
head(1,1:4) = {'層', 'X軸', 'Y軸', 'x方向'};
head(2,4:end) = {'角度', '柱耐力', '', '', '', '梁耐力', '', ...
  '耐力の合計', '', '柱梁'};
head(3,5:end) = {'上柱', '種別', '下柱', '種別', '左梁', '右梁', '柱', ...
  '梁', '耐力比'};
head(4,4:12) = {'度', 'kNm', '', 'kNm', '', 'kNm', 'kNm', 'kNm', 'kNm'};

% 柱梁耐力比の書き出し
body = cell(0,13);
if ncgsr==0 || isempty(cgsr)
  sdrcell.head = head;
  sdrcell.body = body;
  return
end
body = cell(ncgsr,13);
innn = 1:nnode;
icgg = 1:ncgsr;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        in = innn(node.idx==ix & node.idy==iy & node.idz==iz ...
          & node.idstory==ist);
        if isempty(in)
          continue
        end
        icg = icgg(idcg2n==in);
        if isempty(icg)
          continue
        end
        switch icase
          case PRM.EXP
            sg = cgsr.sgx(icg,:);
            sc = cgsr.scx(icg,1:2);
          case PRM.EXN
            sg = cgsr.sgx(icg,:);
            sc = cgsr.scx(icg,3:4);
          case PRM.EYP
            sg = cgsr.sgy(icg,:);
            sc = cgsr.scy(icg,1:2);
          case PRM.EYN
            sg = cgsr.sgy(icg,:);
            sc = cgsr.scy(icg,3:4);
        end
        if sg<0.1
          continue
        end
        irow = irow+1;
        body{irow,1} = node.zname{in};
        body{irow,2} = node.xname{in};
        body{irow,3} = node.yname{in};
        body{irow,4} = 0;
        sr = cgsr.ratio(icg, icase-1);
        body{irow,5} = sprintf('%.1f', sc(2)*1.d-6);
        body{irow,7} = sprintf('%.1f', sc(1)*1.d-6);
        body{irow,9} = sprintf('%.1f', sg(1)*1.d-6);
        body{irow,10} = sprintf('%.1f', sg(2)*1.d-6);
        body{irow,11} = sprintf('%.1f', sum(sc)*1.d-6);
        body{irow,12} = sprintf('%.1f', sum(sg)*1.d-6);
        body{irow,13} = sprintf('%.2f', sr);
      end
    end
  end
end
if irow==0
  body = cell(0,13);
else
  body = body(1:irow,:);
end
sdrcell.head = head;
sdrcell.body = body;
return
end
