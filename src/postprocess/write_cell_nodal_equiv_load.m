function [nlhead, nlbody] = write_cell_nodal_equiv_load(com, result)
%writeSectionProperties - Write section properties

% 定数
nn = com.nnode;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
% feqvec = com.feqvec;
node = com.node;
n2df = com.node.dof;
sw = result.sw;
% fvec = feqvec(:,1)+sw.f;
fnode = com.fnode;
faddnode = com.faddnode;
felement = result.felement;
fvec = fnode(:,1)+faddnode(:,1)-felement(:,1)-sw.f;

% --- 等価節点荷重 ---
nlhead = {...
  '層','X軸','Y軸','PX','PY','PZ','MX','MY','MZ'; ...
  '', '', '', 'kN', 'kN', 'kN', 'kNm', 'kNm', 'kNm'};
nlbody = cell(nn,9);
innn = 1:nn;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      in = innn(node.idx==ix & node.idy==iy & node.idstory== ist ...
        & node.type==PRM.NODE_STANDARD);
      if isempty(in)
        continue
      end
      irow = irow+1;
      nlbody{irow,1} = node.zname{in};
      nlbody{irow,2} = node.xname{in};
      nlbody{irow,3} = node.yname{in};
      idf = n2df(in,[1 2 3 4 5 6]);
      fff = fvec(idf)'.*[1.d-3 1.d-3 1.d-3 1.d-6 1.d-6 1.d-6];
      fff = [fff(1:3) -fff(5) fff(4) fff(6)];
      for j=1:6
        nlbody{irow,3+j} = sprintf('%.2f',fff(j));
      end
    end
  end
end
return
end
