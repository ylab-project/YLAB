function [secbrb, repbrbs, id] = ...
  deprecated_findNearestSectionBrb(secmgr, xvar, idslist, options)
% DEPRECATED: idsec2slistプロパティを使用する旧実装
%FIND_NEIGHBOR_SECTION この関数の概要をここに記述
%   詳細説明をここに記述

% 共通定数
nrepbrbs = secmgr.nrepbrbs;

% 共通配列
idbrbs2repbrbs = secmgr.idbrbs2repbrbs;
idrepbrbs2slist = secmgr.idSectionList(secmgr.idrepbrbs2sec);
idrepbrbs2v = secmgr.idrepbrbs2var;
secdimlist = secmgr.getDimension(idslist);

% 計算準備
repbrbs = zeros(nrepbrbs,2);
repbrbs(idrepbrbs2slist==idslist,1:2) = ...
  xvar(idrepbrbs2v(idrepbrbs2slist==idslist,1:2));
id.slist = zeros(nrepbrbs,1);
id.section = zeros(nrepbrbs,1);
v1list = secdimlist(:,2);
v2list = secdimlist(:,3);
iddd = 1:size(secdimlist,1);

% 断面の検索
for id_=1:nrepbrbs

  % 断面と断面リストが対応しないときはスキップ
  if idrepbrbs2slist(id_)~=idslist
    continue
  end

  % 完全一致なら検索不要
  isok = repbrbs(id_,1)==secdimlist(:,2)...
    &repbrbs(id_,2)==secdimlist(:,3);
  if any(isok)
    idfound = iddd(isok);

    % 断面の保存
    if(length(idfound)>1)
      idfound=idfound(1);
    end
    for j=1:4
      repbrbs(id_,j) = secdimlist(idfound,j);
    end
    id.slist(id_) = idslist;
    id.section(id_) = idfound;
    continue
  end

  % --- ユークリッド距離が最小となる断面の選択 ---
  [~, idfound] = pdist2(secdimlist(:,2:3), repbrbs(id_,1:2),...
      'fastsquaredeuclidean','Smallest',1);
  sss = secdimlist(idfound,:);

  % 断面の保存
  for j=1:4
    repbrbs(id_,j) = sss(j);
  end
  id.slist(id_) = idslist;
  id.section(id_) = idfound;
end
secbrb = repbrbs(idbrbs2repbrbs,:);
id.slist = id.slist(idbrbs2repbrbs);
id.section = id.section(idbrbs2repbrbs);

return
end


