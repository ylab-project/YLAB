function cmq = extractCantileverCMQ(obj)
% データブロックの取り出し
data = obj.dataBlock.get_data_block('片持梁CMoQo表', 'G+P');
dmat = cell2mat(data(:,8:12));

% 計算の準備
% f = zeros(obj.nnode,6);
nrow = size(data,1);
label = cell(nrow,6);
% val = zeros(nrow,5);        % CMQ値（要素ごと）
% arni = zeros(nrow,6);       % 元端等価節点荷重（要素ごと）
% arnj = zeros(nrow,6);       % 先端等価節点荷重（要素ごと）
fari = zeros(obj.nnode,6);   % 元端等価節点荷重（節点ごと）
farj = zeros(obj.nnode,6);   % 先端等価節点荷重（節点ごと）

% cmq_cell = cell(nrow,6);
% val = zeros(nrow,5);

% 梁CMQの読み出し
ncg = 0;
for i=1:nrow
  if ~ismissing(data{i,1})
    ncg = ncg+1;
    label(ncg,:) = data(i,1:6);
    l = data{i,6}*1.d-3;
    % 節点番号の取り出し
    idnode = obj.findIdNode(data{i,1}, data{i,2}, data{i,3});
    if isempty(idnode)
      idnode = obj.findIdNode(data{i,2}, data{i,1}, data{i,3});
      label(ncg,[1 2]) = label(ncg,[2 1]);
    end

    % 跳出方向の判定
    switch data{i,4}
      case '上'
        idm = 4;
        sgn = -1;
      case '下'
        idm = 4;
        sgn = 1;
      case '左'
        idm = 5;
        sgn = -1;
      case '右'
        idm = 5;
        sgn = 1;
    end
  end

% 片持梁合計の取り出し
  if data{i,7}=="合　計"
    % val(ncg,:) = dmat(i,:);
    Ci = dmat(i,1);
    % Cj = dmat(i,3);
    Qi = dmat(i,4);
    Qj = dmat(i,5);
    Mi = sgn*Ci;
    Mj = sgn*Qj*l;
    Q = -Qi-Qj;
    % arni(ncg,[3 idm]) = arni(ncg,[3 idm])+[-Qi Mi];
    % arnj(ncg,[3 idm]) = arnj(ncg,[3 idm])+[-Qj Mj];
    fari(idnode,[3 idm]) = fari(idnode,[3 idm])+[-Qi Mi];
    farj(idnode,[3 idm]) = farj(idnode,[3 idm])+[-Qj Mj];
  end
end

% 結果の保存
% cmq.label = label(1:ncg,:);
% cmq.val = dmat(1:ncg,:);
% cmq.arni = arni(1:ncg,:);
% cmq.arnj = arni(1:ncg,:);
cmq.fari = fari;
cmq.farj = farj;
return
end
