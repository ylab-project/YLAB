function [idnominal, isprimary, idsecc, nominal_column] = ...
  countup_nominal_column(member_column, member_girder, member_brace, com)
%CALC_GIRDER_THROUGH_LENGTH この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
nmc = size(member_column,1);
idconnected = member_column.idconnected;
isthrough = member_column.isthrough;
idnominal = zeros(nmc,2);
idsecc = member_column.idsecc;

% 通し柱のカウント
inc = 0;
for ic=1:nmc
  if ~isthrough(ic,1)
    inc = inc+1;
    idnominal(ic,1) = inc;
    idnominal(ic,2) = 1;
  end
end

% 従属柱のカウント
for ic=1:nmc
  idnext = idconnected(ic);
  if idnext==0
    % 接続部材なし
    continue
  end
  
  if idnominal(ic,2)~=1
    % 開始部材でない
    continue
  end

  % 接続検索
  inc = idnominal(ic,1);
  jnc = 2;
  for ic2=1:1000
    idcur = idnext;
    idnext = idconnected(idnext);
    idnominal(idcur,1) = inc;
    idnominal(idcur,2) = jnc;

    % 接続部材なし
    if (idnext==0 || idnext==-1)
      break
    end

    % 接続部材追加
    jnc = jnc+1;
  end
end

% 主柱
% isprimary = ~isthrough(:,2);
isprimary = ~isthrough(:,1);

% 従属柱の断面番号修正
for ic=1:nmc
  if isprimary(ic)
    continue
  end
  idsecc_ = idsecc(idnominal(ic,1) == idnominal(:,1) & isprimary);
  idsecc(ic) = idsecc_;
end

% 通し柱の数え上げ
maxcol = 10;
nnmc = max(idnominal(:,1));
idmec = zeros(nnmc,maxcol);
idsub = zeros(nnmc,2);
iccc = 1:nmc;
for inc=1:nnmc
  iii = iccc(idnominal(:,1)==inc);
  % 複数部材のまとめ上げ
  % 柱脚側から並べ替え
  [~,iddd] = sort(idnominal(iii,2));
  iii = iii(iddd);
  nnn = length(iii);
  idmec(inc,1:nnn) = iii;
  idsub(inc,1) = 1;
  idsub(inc,2) = nnn;
end
maxcol = max(idsub(:,2));
idmec = idmec(:,1:maxcol);

% 梁・ブレースの接続確認
idnode_girder = unique([member_girder.idnode1; member_girder.idnode2]);
idnode_brace = unique([member_brace.idnode1; member_brace.idnode2]);
is_girder_connected = false(nnmc,maxcol-1);
is_brace_connected = false(nnmc,maxcol-1);
for inc=1:nnmc
  if idsub(inc,2)==1
    % 分割なし
    continue
  end
  for j=1:idsub(inc,2)-1
    idmec_ = idmec(inc,j);
    idnode = member_column.idnode2(idmec_);
    if any(idnode==idnode_girder)
      is_girder_connected(inc,j) = true;
    end
    if any(idnode==idnode_brace)
      is_brace_connected(inc,j) = true;
    end
  end
end

% 許容応力度制約除外判定
isscas = com.exclusion.is_section_column_allowable_stress;
is_allowable_stress = true(nnmc,1);
for inc=1:nnmc
  idmec_ = idmec(inc,1);
  idsecc_ = idsecc(idmec_);
  is_allowable_stress(inc) = isscas(idsecc_);
end

% 結果の保存
nominal_column = table(idmec, idsub, ...
  is_girder_connected, is_brace_connected, is_allowable_stress);
return
end

