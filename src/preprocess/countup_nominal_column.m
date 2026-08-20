function [idnominal, isprimary, idsecc, nominal_column] = ...
  countup_nominal_column(member_column, member_girder, member_brace, com)
%countup_nominal_column - 通し柱を名目柱として集約する
%
%   [idnominal, isprimary, idsecc, nominal_column] =
%     countup_nominal_column(member_column, member_girder, ...
%     member_brace, com) は、柱の接続関係をたどって通し柱を
%   集約し、構成要素、接続部材および接合条件を持つ名目柱
%   テーブルを生成する。
%
%   入力引数:
%     member_column - 柱部材テーブル
%     member_girder - 梁部材テーブル
%     member_brace  - ブレース部材テーブル
%     com           - 共通データ構造体
%
%   出力引数:
%     idnominal    - 柱から名目柱への逆引き [nmc×2]
%     isprimary    - 各名目柱の柱脚側代表要素 [nmc×1]
%     idsecc       - 名目柱内で統一した柱断面番号 [nmc×1]
%     nominal_column - 名目柱テーブル

% 計算の準備
if istable(member_column)
  nmc = height(member_column);
else
  nmc = length(member_column.idsecc);
end
idconnected = member_column.idconnected;
member_isthrough = member_column.isthrough;
idnominal = zeros(nmc, 2);
idsecc = member_column.idsecc;

% 柱脚側の代表要素に名目柱番号を割り当てる
isprimary = ~member_isthrough(:, 1);
idnominal(isprimary, 1) = (1:nnz(isprimary)).';
idnominal(isprimary, 2) = 1;

% 接続関係を柱脚から柱頭へたどり、構成要素の順序を記録する
for ic = 1:nmc
  idnext = idconnected(ic);
  if idnext == 0
    continue
  end
  if idnominal(ic, 2) ~= 1
    continue
  end

  inc = idnominal(ic, 1);
  jnc = 2;
  for istep = 1:1000
    idcur = idnext;
    idnext = idconnected(idnext);
    idnominal(idcur, 1) = inc;
    idnominal(idcur, 2) = jnc;
    if idnext == 0 || idnext == -1
      break
    end
    jnc = jnc + 1;
  end
end

% 従属要素の断面番号を代表要素の断面へ揃える
for ic = 1:nmc
  if isprimary(ic)
    continue
  end
  is_same_nominal = idnominal(:, 1) == idnominal(ic, 1);
  idsecc(ic) = idsecc(is_same_nominal & isprimary);
end

% 名目柱ごとに柱脚から柱頭の順で構成要素を格納する
maxcol = 10;
nnmc = max(idnominal(:, 1));
idmec = zeros(nnmc, maxcol);
idsub = zeros(nnmc, 2);
for inc = 1:nnmc
  ids = find(idnominal(:, 1) == inc).';
  [~, idsort] = sort(idnominal(ids, 2));
  ids = ids(idsort);
  nsub = length(ids);
  idmec(inc, 1:nsub) = ids;
  idsub(inc, :) = [1, nsub];
end
maxcol = max(idsub(:, 2));
idmec = idmec(:, 1:maxcol);

% 内部節点に接続する梁とブレースを記録する
idnode_girder = unique([member_girder.idnode1; member_girder.idnode2]);
idnode_brace = unique([member_brace.idnode1; member_brace.idnode2]);
is_girder_connected = false(nnmc, maxcol - 1);
is_brace_connected = false(nnmc, maxcol - 1);
for inc = 1:nnmc
  nsub = idsub(inc, 2);
  if nsub == 1
    continue
  end
  for isub = 1:nsub - 1
    ic = idmec(inc, isub);
    idnode = member_column.idnode2(ic);
    is_girder_connected(inc, isub) = any(idnode == idnode_girder);
    is_brace_connected(inc, isub) = any(idnode == idnode_brace);
  end
end

% 許容応力度制約の適用条件は柱脚側代表要素の断面から取得する
section_is_allowable = com.exclusion.is_section_column_allowable_stress;
is_allowable_stress = true(nnmc, 1);
for inc = 1:nnmc
  ic = idmec(inc, 1);
  is_allowable_stress(inc) = section_is_allowable(idsecc(ic));
end

% 通し柱指定による集約とブレース脚分割を区別する
isthrough = false(nnmc, 1);
for inc = 1:nnmc
  nsub = idsub(inc, 2);
  if nsub == 1
    continue
  end
  ids = idmec(inc, 1:nsub);
  is_brace_split = ...
    member_column.type(ids) == PRM.COLUMN_FOR_BRACE_FOUNDATION ...
    | member_column.type(ids) == PRM.COLUMN_FOR_BRACE_BODY;
  isthrough(inc) = ~any(is_brace_split);
end

% 解析用分割要素から分割前の柱脚・柱頭接合条件を組み立てる
joint = countup_nominal_column_joint(member_column, idmec, idsub);

nominal_column = table(idmec, idsub, isthrough, is_girder_connected, ...
  is_brace_connected, is_allowable_stress, joint);

return
end
