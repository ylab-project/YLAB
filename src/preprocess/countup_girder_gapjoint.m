function [gapjoint, idgapsec, idgapvar] = countup_girder_gapjoint(com)
%countup_girder_gapjoint - 梁せい差の対象接合部とペアを数え上げる
%
%   [gapjoint, idgapsec, idgapvar] = countup_girder_gapjoint(com) は、
%   複数種類のH形鋼梁がとりつく接合部を数え上げ、梁せい差制約用の
%   H変数ペアと断面ペアを返す。せい(H)を設計変数に持つのはH形鋼
%   だけなので、RC梁と鋼管梁は対象外とする。段差ペアは少なくとも
%   一方が動かせることを条件とし、全変数が固定の節点、固定×固定の
%   変数ペア、動かせない断面同士の寸法ペアは対象から除外する。
%
%   入力引数:
%     com - 共通データ構造体
%
%   出力引数:
%     gapjoint - 対象接合部テーブル（idnode, idvar）
%     idgapsec - 梁せい差（寸法）の断面ペア [ngs×2]
%     idgapvar - 梁せい差（呼称）のH変数ペア [ngv×2]

% 共通定数
nnode = com.nnode;
nstory = com.nstory;
maxcol = 10;

% 共通配列
idm2var = com.member.property.idvar;
idm2n1 = com.member.property.idnode1;
idm2n2 = com.member.property.idnode2;
idm2s = com.member.property.idsec;
idn2s = com.node.idstory;
mtype = com.member.property.type;
mstype = com.member.property.section_type;
isv = com.design.variable.isvar > 0;   % 未使用スロットは論理偽

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
  ismeg = isconnected&mtype==PRM.GIRDER&mstype==PRM.WFS;
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

% 動かせない断面同士の寸法ペアを削除（H変数なし・固定変数を除外）
idsec2varH = com.section.property.idvar(:,1);
has_var = idsec2varH > 0;
canmove = false(size(idsec2varH));
canmove(has_var) = isv(idsec2varH(has_var));
idgapsec = keep_movable_pairs(idgapsec, canmove);

% 重複行を除外（nvarH>1の除外は43行目で実施済み）
[~,ia] = unique(idvarofH,'rows');
istarget = false(ngapjoint,1); istarget(ia) = true;
idnode = idnode(istarget,:);
idvar = idvarofH(istarget,:);
 
% 除外部材の削除（0パディングは実変数と誤認しないよう除く）
istarget = false(size(idvar));
ispos = idvar>0;
istarget(ispos) = isv(idvar(ispos));
istarget = any(istarget, 2);
idnode = idnode(istarget,:);
idvar = idvar(istarget,:);
gapjoint = table(idnode, idvar);

% H変数の組の算出
idvar_ = unique(idvar,'rows');
n = size(idvar_,1);
idgapvar = cell(n,1);
for i=1:n
  ttt = idvar_(i,:);
  ttt = ttt(ttt > 0);
  if numel(ttt) < 2
    idgapvar{i} = zeros(0,2);
  else
    idgapvar{i} = nchoosek(ttt,2);
  end
end
idgapvar = cell2mat(idgapvar);
if isempty(idgapvar)
  idgapvar = zeros(0,2);
else
  idgapvar = unique(idgapvar,'rows');
  idgapvar = keep_movable_pairs(idgapvar, isv);
end

return
end

%--------------------------------------------------------------------------
function pairs = keep_movable_pairs(pairs, canmove)
%keep_movable_pairs - 少なくとも一方が動かせるペアだけ残す
%
%   pairs = keep_movable_pairs(pairs, canmove) は、両端とも動かせない
%   ペアを取り除く。段差制約は片側でも動かせれば解消できる。
%
%   入力引数:
%     pairs   - IDペア [n×2]
%     canmove - IDごとの可動フラグ（論理）
%
%   出力引数:
%     pairs - 少なくとも一方が動かせるペア
pairs = pairs(canmove(pairs(:,1)) | canmove(pairs(:,2)), :);
return
end
