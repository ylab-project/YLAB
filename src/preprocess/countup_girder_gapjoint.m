function [gapjoint, idgapsec, idgapvar] = countup_girder_gapjoint(com)
% 共通定数
nnode = com.nnode;
nstory = com.nstory;
nvar = com.nvar;
maxcol = 10;

% 共通配列
idm2var = com.member.property.idvar;
idm2n1 = com.member.property.idnode1;
idm2n2 = com.member.property.idnode2;
idm2s = com.member.property.idsec;
idn2s = com.node.idstory;
mtype = com.member.property.type;

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
% nsecg = zeros(ngapjoint,1);
idsec = nan(ngapjoint,10);
nvarH = zeros(ngapjoint,1);
idvarofH = zeros(ngapjoint,maxcol);

% 同じ接合部にとりつく梁Hの数え上げ
for i = 1:ngapjoint
  in = idnode(i);
  isconnected = (idm2n1==in)|(idm2n2==in);
  ismeg = isconnected&mtype==PRM.GIRDER;
  idsec(i,1:length(idm2s(ismeg))) = idm2s(ismeg);
  idvarofH_ = unique(idm2var(ismeg,1));
  nvarH(i) = length(idvarofH_);
  idvarofH(i,1:nvarH(i)) = idvarofH_;
end

% 取り付く梁が1種類しかない接合部は除外（ms計算より前に実施）
istarget = nvarH>1;
idsec = idsec(istarget,:);
idvarofH = idvarofH(istarget,:);
idnode = idnode(istarget);
ngapjoint = sum(istarget);

% 対象接合部がない場合は空を返す
if ngapjoint == 0
  gapjoint = table();
  idgapsec = zeros(0,2);
  idgapvar = cell(0,1);
  return
end

% 除外後にms計算
ms = max(sum(~isnan(idsec),2));
idsec = idsec(:,1:ms);
mv = max(sum(idvarofH>0,2));
idvarofH = idvarofH(:,1:mv);

% 断面別の数え上げ準備
idtmp = inf(ngapjoint,ms);
for i=1:ngapjoint
  uuu = unique(idsec(i,:));
  mu = sum(~isnan(uuu));
  idtmp(i,1:mu) = uuu(1:mu);
end
idtmp = unique(idtmp,'rows');

% 断面別の数え上げ
ntmp = size(idtmp,1);
mtmp = nchoosek(ms,2);
ngsmax = ntmp*mtmp;
idgapsec = zeros(ngsmax,2);
for i=1:ntmp
  ttt = nchoosek(idtmp(i,:),2);
  idgapsec((i-1)*mtmp+1:i*mtmp,:) = ttt;
end
idgapsec(any(idgapsec==inf,2),:) = [];
idgapsec = unique(idgapsec,'rows');

% 重複行を除外（nvarH>1の除外は43行目で実施済み）
[~,ia] = unique(idvarofH,'rows');
istarget = false(ngapjoint,1); istarget(ia) = true;
idnode = idnode(istarget,:);
idvar = idvarofH(istarget,:);
 
% 除外部材の削除
idexclude = (1:nvar)';
idexclude = idexclude(~com.design.variable.isvar);
n = size(idvar,1); istarget = true(n,2);
for i=1:length(idexclude)
  if isempty(istarget)
    break
  end
  istarget = istarget&(idvar~=idexclude(i));
end
istarget = any(istarget,2);
idnode = idnode(istarget,:);
idvar = idvar(istarget,:);
gapjoint = table(idnode, idvar);

% H変数の組の算出
idvar_ = unique(idvar,'rows');
n = size(idvar_,1);
idgapvar = cell(n,1);
for i=1:n
  ttt = idvar_(i,:);
  idgapvar{i} = nchoosek(ttt(1:nnz(ttt)),2);
end
idgapvar = unique(cell2mat(idgapvar),'rows');

return
end
