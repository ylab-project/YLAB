function [wfsec, repwfs, id] = ...
  deprecated_findNearestSectionWfs(secmgr, xvar, idslist, options)
% DEPRECATED: idsec2slistプロパティを使用する旧実装
%FIND_NEIGHBOR_SECTION この関数の概要をここに記述
%   詳細説明をここに記述

% 共通定数
nrepwfs = secmgr.nrepwfs;

% 共通配列
idwfs2repwfs = secmgr.idwfs2repwfs;
idrepwfs2wfs = secmgr.idrepwfs2wfs;
% idwfs2slist = secmgr.idwfs2slist;
idrepwfs2slist = secmgr.idSectionList(secmgr.idrepwfs2sec);
idrepwfs2v = secmgr.idrepwfs2var;
secdimlist_all = secmgr.getDimension(idslist);
isvalid = secmgr.getValidSectionOfSlist(idslist);

% 計算準備
repwfs = zeros(nrepwfs,5);
repwfs(idrepwfs2slist==idslist,1:4) = ...
  xvar(idrepwfs2v(idrepwfs2slist==idslist,1:4));
id.slist = zeros(nrepwfs,1);
id.section = zeros(nrepwfs,1);
is_small_H = repwfs(:,1)<200;
repwfs(is_small_H,1) = round(repwfs(is_small_H,1)/25)*25;
repwfs(~is_small_H,2) = round(repwfs(~is_small_H,2)/50)*50;
% [~, idu1, idu2] = unique([repwfs idrepwfs2slist], 'rows', 'stable');

% 断面の検索
for id_=1:nrepwfs

  % 断面と断面リストが対応しないときはスキップ
  if idrepwfs2slist(id_)~=idslist
    continue
  end

  % 適合断面の抽出
  idwfs = idrepwfs2wfs(id_);
  isvalid_ = isvalid(idwfs,:);
  secdimlist = secdimlist_all(isvalid_,:);
  rtwlist = secdimlist(:,1)./secdimlist(:,3);
  rtflist = secdimlist(:,2)./secdimlist(:,4);
  Hnom = secdimlist(:,PRM.SECDIM_WFS_H_NOM);
  Bnom = secdimlist(:,PRM.SECDIM_WFS_B_NOM);
  iddd = 1:size(secdimlist,1);
  id_2id = 1:size(secdimlist_all,1); id_2id = id_2id(isvalid_);

  % 完全一致なら検索不要
  isok = repwfs(id_,1)==Hnom...
    &repwfs(id_,2)==Bnom ...
    &repwfs(id_,3)==secdimlist(:,3) ...
    &repwfs(id_,4)==secdimlist(:,4);
  if any(isok)
    idfound = iddd(isok);
    
    % 断面の保存
    if(length(idfound)>1)
      idfound=idfound(1);
    end
    for j=1:5
      repwfs(id_,j) = secdimlist(idfound,j);
    end
    id.slist(id_) = idslist;
    % id.section(id_) = idfound;
    id.section(id_) = id_2id(idfound);
    continue
  end

  % --- ユークリッド距離が最小となる断面の選択 ---
  % [~, idlist] = pdist2(slist(:,[6 7 3 4]), repwfs(id,1:4),...
  %     'fastsquaredeuclidean','Smallest',1);
  % sss = slist(idlist,:);

  % --- 幅厚比距離が最小となる断面の選択 ---
  % Hを固定し，最も近いBを検索 → xのH,Bは呼び寸(nominal値)
  % xvarからBiと対応するHiの取り出し
  idH = idrepwfs2v(id_,1);
  idB = idrepwfs2v(id_,2);
  Hi = xvar(idH);
  Bi = xvar(idB);

  % Hiに適合する規格断面からBiに最も近いBを採用
  isGivenH = abs(Hnom-Hi)<=options.tolHgap;
  if any(isGivenH)
    % 該当断面あり->最小距離断面の選択
    ddd = abs(Bnom-Bi);
    [~, idfound] = min(ddd(isGivenH));
    iii = iddd(isGivenH);
    idfound = iii(idfound);
  else
    % 該当断面なし
    [~,idfound] = min(abs(Hnom-Hi));
    idfound = idfound(1);
  end
  repwfs(id_,1:2) = [Hnom(idfound) Bnom(idfound)];

  % 幅厚比の計算
  rtw = repwfs(id_,1)./repwfs(id_,3);
  rtf = repwfs(id_,2)./repwfs(id_,4);

  % H,Bを固定し，最も近いtw,tfを検索 -> H,Bは実寸に書き換え
  % Hi,Biに適合する規格断面のチェック
  % isGivenH = abs(Hlist-repwfs(id,1))<=options.tolHgap;
  % isGivenB = abs(Blist-repwfs(id,2))<=options.tolBgap;
  isGivenB = abs(Bnom-repwfs(id_,2))<=options.tolBgap;
  isGiven = isGivenH&isGivenB;

  if any(isGiven)
    % 該当断面あり->最小距離断面の選択
    ddd = (rtwlist-rtw).^2+(rtflist-rtf).^2;
    [~, idl_] = min(ddd(isGiven));
    % sss = seclist(isGiven,:);
    % sss = sss(idl_,:);
    iii = iddd(isGiven);
    idfound = iii(idl_);
    sss = secdimlist(idfound,:);
  else
    % 該当断面なし
    sss = secdimlist(idfound,:);
  end

  % 断面の保存
  for j=1:5
    repwfs(id_,j) = sss(j);
  end
  id.slist(id_) = idslist;
  % id.section(id_) = idfound;
  id.section(id_) = id_2id(idfound);
end
wfsec = repwfs(idwfs2repwfs,:);
id.slist = id.slist(idwfs2repwfs);
id.section = id.section(idwfs2repwfs);
return
end
