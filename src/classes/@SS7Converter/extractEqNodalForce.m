function feq = extractEqNodalForce(obj)
% データブロックの取り出し
data = obj.dataBlock.get_data_block('等価節点荷重','G+P');
dmat = cell2mat(data(:,4:9));

% 計算の準備
feq = zeros(obj.nnode,6);
nrow = size(data,1);

% 等価節点荷重の読み出し
for i=1:nrow
  % 節点番号の取り出し
  idnode = obj.findIdNode(data{i,2}, data{i,3}, data{i,1});
  if isempty(idnode)
    continue
  end
  feq(idnode,:) = dmat(i,:);
end

% SS7の座標系から変換
mx = -feq(:,5);
my = feq(:,4);
feq(:,4:5) = [mx my];
end
