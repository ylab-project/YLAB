function [head, body] = write_cell_nodal_displacement(com, result, icase)
%writeSectionProperties - Write section properties

% 定数
nn = com.nnode;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
% story = com.story;
dnode = result.dnode;
% feqvec = com.feqvec;
node = com.node;
% n2df = com.node.dof;
% sw = result.sw;

% --- 変位量（重心位置） ---
head = {
  '層', 'X軸', 'Y軸', 'X', 'Y', 'Z', 'θX', 'θY', 'θZ'; ...
  '', '', '', 'mm', 'mm', 'mm', 'rad', 'rad', 'rad'};
body = cell(nn,9);
innn = 1:nn;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      in = innn(node.idx==ix & node.idy==iy & node.idstory== ist);
      if isempty(in)
        continue
      end
      irow = irow+1;
      body{irow,1} = node.zname{in};
      body{irow,2} = node.xname{in};
      body{irow,3} = node.yname{in};
      ddd = dnode(in, :, icase);
      ddd = [ddd(1:3) -ddd(5) ddd(4) ddd(6)];
      for j=1:6
        body{irow,3+j} = sprintf('%.3f',ddd(j));
      end
      for j=4:6
        body{irow,3+j} = sprintf('%.5f',ddd(j));
      end
    end
  end
end
return
end
