function nodalWeight = extractNodalWeight(obj)
% データブロックの取り出し
data = obj.dataBlock.get_data_block('節点重量表(固定+積載)');

% 計算の準備
farz = zeros(obj.nnode,1);
fgz = zeros(obj.nnode,1);
fcz = zeros(obj.nnode,1);
fwz = zeros(obj.nnode,1);
fez = zeros(obj.nnode,1);
nrow = size(data,1);
for i=1:nrow
  if ~ismissing(data{i,1})
    idnode = obj.findIdNode(data{i,1}, data{i,2}, data{i,3});
    if ~ismissing(data{i,4})
      % 床自重
      farz(idnode) = farz(idnode)+data{i,4};
    end
  else
    % 床自重
    if ~ismissing(data{i,4})
      farz(idnode) = farz(idnode)+data{i,4};
    end
    % 梁自重
    if ~ismissing(data{i,5})
      fgz(idnode) = fgz(idnode)+data{i,5};
    end
    % 壁自重
    if ~ismissing(data{i,6})
      fwz(idnode) = fwz(idnode)+data{i,6};
    end
    % 特殊荷重
    if ~ismissing(data{i,7})
      farz(idnode) = farz(idnode)+data{i,7};
    end
    % 柱自重
    if ~ismissing(data{i,8})
      fcz(idnode) = fcz(idnode)+data{i,8};
    end
    % 補正
    if ~ismissing(data{i,9})
      fez(idnode) = fez(idnode)+data{i,9};
    end
  end
end
nodalWeight.farz = -farz;
nodalWeight.fgz = -fgz;
nodalWeight.fcz = -fcz;
nodalWeight.fwz = -fwz;
nodalWeight.fez = -fez;
end
