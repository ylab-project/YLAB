function [girderLoad, header] = writeCellGirderLoad(obj)
% 計算の準備
ngcmq = size(obj.girderCMQ.ar,1);
girderLoad = cell(ngcmq+obj.nstory*4,18);
glabel = obj.girderCMQ.label;
ar = obj.girderCMQ.ar;

% ヘッダー
header = {'%荷重ケース', '層', 'フレーム', '軸', '軸', ...
  'Fxi', 'Fyi', 'Fzi', 'Mxi', 'Myi', ...
  '', 'Mzi', 'Fxj', 'Fzj', 'Mxj', ...
  'Myj', 'Mzj', 'M0'; ...
  '%', '', '', '', '', ...
  'N', 'N', 'N', 'N.mm', 'N.mm', 'N.mm' ...
  'N', 'N', 'N', 'N.mm' ...
  'N.mm', 'N.mm', 'N.mm'};

% 梁要素荷重の書き出し
irow = 0;

% 長期荷重
for i=1:ngcmq
  if all(ar(i,:)<0.1)
    continue
  end
  irow = irow+1;
  girderLoad{irow,1} = 'G+P';
  girderLoad(irow,2:5) = glabel(i,:);
  arm = ar(i,:).*[1.d3 1.d3 1.d3 1.d6 1.d6 1.d6 ...
    1.d3 1.d3 1.d3 1.d6 1.d6 1.d6 1.d6];
  girderLoad(irow,6:18) = num2cell(arm);
end

% 結果の整理
girderLoad = girderLoad(1:irow,:);
end

