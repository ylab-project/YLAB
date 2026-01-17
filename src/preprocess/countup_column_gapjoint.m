function gapjoint = countup_column_gapjoint(com)
% 共通定数
nmec = com.nmec;
nnode = com.nnode;
nstory = com.nstory;

% 共通配列
idmec2var = com.member.column.idvar;
idmec2n1 = com.member.column.idnode1;
idmec2n2 = com.member.column.idnode2;
idn2s = com.node.idstory;
idn2xy = [com.node.idx com.node.idy];
% RC柱判定用
column_type = com.section.column.type(com.member.column.idsecc);
% mtype = com.member.property.type;

% 接合部数の数え上げ
% TODO 対象階の指定方法を要見直し
isset = 2:nstory;
is_target_joint = false(nnode,1);
for is=isset
  is_target_joint(idn2s==is) = true;
end
ngapjoint = sum(+is_target_joint);

% 計算の準備
idnode_all = (1:nnode)'; idnode_all = idnode_all(is_target_joint);

% 結果格納用（動的に拡張）
result_idnode = [];
result_idvar = [];

% 同じ接合部にとりつく柱外径の数え上げ
immm = 1:nmec;
for i = 1:ngapjoint
  in = idnode_all(i);
  idmec1 = immm(idmec2n1==in);  %上階柱部材番号（柱下端が接続→上側の柱）
  idmec2 = immm(idmec2n2==in);  %下階柱部材番号（柱上端が接続→下側の柱）

  % 空チェック（上下どちらかがなければ除外）※複数柱チェックより先
  if isempty(idmec1) || isempty(idmec2)
    continue
  end

  % 複数柱が接続する場合は全ペアの組み合わせを対象
  for j1 = 1:length(idmec1)
    for j2 = 1:length(idmec2)
      mc1 = idmec1(j1);
      mc2 = idmec2(j2);

      % RC柱が含まれる場合は除外
      if column_type(mc1) == PRM.RCRS || column_type(mc2) == PRM.RCRS
        continue
      end

      % 同じ変数の場合も除外
      var1 = idmec2var(mc1,1);
      var2 = idmec2var(mc2,1);
      if var1 == var2
        continue
      end

      % ペアを追加
      result_idnode = [result_idnode; in]; %#ok<AGROW>
      result_idvar = [result_idvar; var1 var2]; %#ok<AGROW>
    end
  end
end

% 結果が空の場合
if isempty(result_idnode)
  idnode = zeros(0,1);
  idxy = zeros(0,2);
  idvar = zeros(0,2);
  gapjoint = table(idnode, idxy, idvar);
  return
end

% 重複を除去
[idvar, ia] = unique(result_idvar,'rows');
idnode = result_idnode(ia);
idxy = idn2xy(idnode,:);
gapjoint = table(idnode, idxy, idvar);
gapjoint = sortrows(gapjoint,[2 3]);
return
end

