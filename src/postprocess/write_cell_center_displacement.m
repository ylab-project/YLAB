function [cdhead, cdbody] = ...
  write_cell_center_displacement(com, result, icase)
%writeSectionProperties - Write section properties

% 定数
nstory = com.nstory;

% 共通配列
story = com.story;
dvec = result.dvec;
n2df = com.node.dof;

% --- 変位量（重心位置） ---
cdhead = {'層', 'Ux', 'Uy', 'φ'; '', 'mm', 'mm', 'rad'};
cdbody = cell(nstory,4);
irow = 0;
isemptyrow = false(1,nstory);
for i = 1:nstory
  ist = nstory-i+1;
  in = story.idnoderep(ist);
  if isnan(in)
    isemptyrow(ist) = true;
    continue
  end
  irow = irow+1;
  cdbody{irow,1} = story.name{ist};
  ddd = dvec(n2df(in, [1 2 6]), icase);
  for j=1:3
    cdbody{irow,1+j} = sprintf('%.5f',ddd(j));
  end
end
cdbody(isemptyrow,:) = [];
return
end
