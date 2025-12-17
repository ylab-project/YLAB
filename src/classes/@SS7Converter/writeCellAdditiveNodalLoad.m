function [addNodalLoad, header] = writeCellAdditiveNodalLoad(obj)
% 計算の準備
fcan = obj.cantileverCMQ.farj;
ncan = size(fcan,1);
% ncan = size(canCMQ.arn,1);
addNodalLoad = cell(ncan,9);
nodecell = table2cell(obj.node);
% storyName = obj.story.name;
% node = obj.node;

% ヘッダー
header = {'%荷重ケース', '層', 'X軸', 'Y軸', 'Fx', ...
  'Fy', 'Fz', 'Mx', 'My', 'Mz'};

% 追加節点荷重の書き出し
irow = 0;
% for i=1:ncan
%   % if (abs(fz(i))<3)
%   %   continue
%   % end
%   irow = irow+1;
%   addNodalLoad{irow,1} = 'G+P';
%   addNodalLoad(irow,2:4) = canCMQ.label(i,[3 1 2]);
%   % addNodalLoad(irow,5:10) = {0 0 0 0 0 0};
%   % addNodalLoad{irow,7} = fz(i)*1.d3;
%   addNodalLoad(irow,5:10) = ...
%     num2cell(canCMQ.arn(i,:).*[1.d3 1.d3 1.d3 1.d6 1.d6 1.d6]);
% end

for i=1:obj.nnode
  % 片持梁分
  if any(abs(fcan(i,:))>0)
    irow = irow+1;
    addNodalLoad{irow,1} = 'G+P';
    addNodalLoad(irow,2:4) = nodecell(i,[3 1 2]);
    addNodalLoad(irow,5:10) = num2cell(fcan(i,:).*[1.d3 1.d3 1.d3 1.d6 1.d6 1.d6]);    
  end
end

% 結果の整理
addNodalLoad = addNodalLoad(1:irow,:);
end
