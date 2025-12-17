function [nodalLoad, header] = writeCellNodalLoad(obj)
% 計算の準備
nodalLoad = cell(obj.nnode*2,9);
nodecell = table2cell(obj.node);
storyName = obj.story.name;
node = obj.node;
eq = obj.earthquake;
fcan = obj.cantileverCMQ.fari;

% ヘッダー
header = {'%荷重ケース', '層', 'X軸', 'Y軸', 'Fx', ...
  'Fy', 'Fz', 'Mx', 'My', 'Mz'};

% 節点荷重の書き出し
irow = 0;
fgz = obj.girderCMQ.fsg(:,3)+obj.girderCMQ.far(:,3) ...
  +obj.cantileverCMQ.fari(:,3);
fcz = obj.nodalWeight.fcz;
fz = obj.nodalWeight.feq(:,3)-fgz-fcz;
fz(abs(fz)<3) = 0;

for i=1:obj.nnode
  % 節点荷重
  % fz = obj.nodalWeight.feq(i,3)+ ...
  %   +obj.girderCMQ.far(i,3) ...
  %   +obj.girderCMQ.fsw(i,3) ...
  %   ...+obj.nodalWeight.fgz(i) ...
  %   +obj.nodalWeight.fcz(i);
  % f = obj.nodalWeight.fcan(i,:);
  % f = f-obj.cmqcan(i,:);
  % f(3) = f(3)+fz;
  if (abs(fz(i))>3)
    irow = irow+1;
    nodalLoad{irow,1} = 'G+P';
    nodalLoad(irow,2:4) = nodecell(i,[3 1 2]);
    nodalLoad(irow,5:10) = {0 0 0 0 0 0};
    nodalLoad{irow,7} = fz(i)*1.d3;
    % nodalLoad(irow,5:10) = num2cell(f.*[1.d3 1.d3 1.d3 1.d6 1.d6 1.d6]);
  end

  % 片持梁分
  if any(abs(fcan(i,:))>0)
    irow = irow+1;
    nodalLoad{irow,1} = 'G+P';
    nodalLoad(irow,2:4) = nodecell(i,[3 1 2]);
    nodalLoad(irow,5:10) = num2cell(fcan(i,:).*[1.d3 1.d3 1.d3 1.d6 1.d6 1.d6]);    
  end
end

% 地震荷重
lclabel = {'EX+', 'EX-', 'EY+', 'EY-'};
innn = 1:obj.nnode;
for ilc=1:4
  for is=1:obj.nstory
    if all(eq.idstory~=is)
      continue
    end
    irow = irow+1;
    p = eq.p(eq.idstory==is,:)*1.d3;
    load = {0 0 0 0 0 0};
    switch ilc
      case 1
        load{1} = p;
      case 2
        load{1} = -p;
      case 3
        load{2} = p;
      case 4
        load{2} = -p;
    end
    nodalLoad{irow,1} = lclabel{ilc};
    nodalLoad{irow,2} = storyName{is};
    idn = innn(node.idstory==is);
    idn = idn(1);
    nodalLoad{irow,3} = node.xname{idn};
    nodalLoad{irow,4} = node.yname{idn};
    nodalLoad(irow,5:10) = load;
  end
end


% 結果の整理
nodalLoad = nodalLoad(1:irow,:);
end
