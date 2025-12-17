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
idnode = (1:nnode)'; idnode = idnode(is_target_joint);
idvarofD = nan(ngapjoint,2);

% 同じ接合部にとりつく柱外径の数え上げ
istarget = true(1,ngapjoint);
immm = 1:nmec;
for i = 1:ngapjoint
  in = idnode(i);
  idmec1 = immm(idmec2n1==in);  %上階柱部材番号
  idmec2 = immm(idmec2n2==in);  %下階柱部材番号
  
  % 空チェック
  if isempty(idmec1) || isempty(idmec2)
    istarget(i) = false;
    continue
  end
  
  % RC柱が含まれる場合は除外
  if column_type(idmec1) == PRM.RCRS || column_type(idmec2) == PRM.RCRS
    istarget(i) = false;
    continue
  end
  
  % 同じ変数の場合も除外
  if idmec2var(idmec1,1)==idmec2var(idmec2,1)
    istarget(i) = false;
    continue
  end
  
  % idsec(i,1) = idm2s(idmec1);
  % idsec(i,2) = idm2s(idmec2);
  idvarofD(i,1) = idmec2var(idmec1,1);
  idvarofD(i,2) = idmec2var(idmec2,1);
end
[idvar, ia] = unique(idvarofD(istarget,:),'rows');
idnode = idnode(istarget);
idnode = idnode(ia);
idxy = idn2xy(idnode,:);
gapjoint = table(idnode, idxy, idvar);
gapjoint = sortrows(gapjoint,[2 3]);
return
end

