function cmq = extractGirderCMQ(obj)
% データブロックの取り出し
data = obj.dataBlock.get_data_block('梁CMoQo表');

% 計算の準備
x = obj.node.x;
y = obj.node.y;
z = obj.node.z;
nrow = size(data,1);
label = cell(nrow,4);
ar = zeros(nrow,13);        % 固定端力（梁自重以外）
sg = zeros(nrow,13);        % 固定端力（梁自重）
far = zeros(obj.nnode,6);   % 等価節点荷重（梁自重以外）
fsg = zeros(obj.nnode,6);   % 等価節点荷重（梁自重）

% 梁CMQの読み出し
ng = 0;
an = 0;
for i=1:nrow
  if ~ismissing(data{i,1})
    ng = ng+1;
    label(ng,:) = data(i,[4 1 2 3]);
    [idnode, idir] = obj.findGirderNode(...
      data{i,1}, data{i,2}, data{i,3}, data{i,4});
    [cyl, cxl] = ystar(x(idnode(1)), y(idnode(1)), z(idnode(1)), ...
      x(idnode(2)), y(idnode(2)), z(idnode(2)), an);
    czl = cross(cxl, cyl, 2);
    t = [cxl; cyl; czl];
  end
  arm = [0 0 data{i,12} 0 -data{i,9} 0 ...
    0 0 data{i,13} 0 data{i,11} 0 data{i,10}];
  fim = [arm(1:3)*t arm(4:6)*t];
  fjm = [arm(7:9)*t arm(10:12)*t];
  loadtype = data{i,8};
  switch loadtype
    % case '床荷重'
    %   ar(ng,:) = ar(ng,:)+arm;
    %   far(idnode(1),:) = far(idnode(1),:)+fim;
    %   far(idnode(2),:) = far(idnode(2),:)+fjm;
    case '自　重'
      sg(ng,:) = sg(ng,:)+arm;
      fsg(idnode(1),:) = fsg(idnode(1),:)+fim;
      fsg(idnode(2),:) = fsg(idnode(2),:)+fjm;
    % case '壁'
    %   ar(ng,:) = ar(ng,:)+arm;
    %   far(idnode(1),:) = far(idnode(1),:)+fim;
    %   far(idnode(2),:) = far(idnode(2),:)+fjm;
    % case '小梁荷重'
    %   ar(ng,:) = ar(ng,:)+arm;
    %   far(idnode(1),:) = far(idnode(1),:)+fim;
    %   far(idnode(2),:) = far(idnode(2),:)+fjm;
    % case '特殊荷重1'
    %   ar(ng,:) = ar(ng,:)+arm;
    %   far(idnode(1),:) = far(idnode(1),:)+fim;
    %   far(idnode(2),:) = far(idnode(2),:)+fjm;
    case '合　計'
      ar(ng,:) = ar(ng,:)+arm;
      far(idnode(1),:) = far(idnode(1),:)+fim;
      far(idnode(2),:) = far(idnode(2),:)+fjm;
  end
end

% 結果の整理
cmq.label = label(1:ng,:);
cmq.sg = sg(1:ng,:);                
cmq.ar = ar(1:ng,:)-sg(1:ng,:);     
cmq.fsg = -fsg;                      
cmq.far = -far+fsg;                  
end
