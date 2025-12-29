function [sechss, rephss, id] = ...
  deprecated_findNearestSectionHss(secmgr, xvar, idslist, options)
% DEPRECATED: idsec2slistプロパティを使用する旧実装
%FIND_NEIGHBOR_SECTION この関数の概要をここに記述
%   詳細説明をここに記述

% 共通定数
nrephss = secmgr.nrephss;

% 共通配列
idhss2rephss = secmgr.idhss2rephss;
idrephss2hss = secmgr.idrephss2hss;
idrephss2slist = secmgr.idSectionList(secmgr.idrephss2sec);
idrephss2v = secmgr.idrephss2var;
secdimlist_all = secmgr.getDimension(idslist);
isvalid = secmgr.getValidSectionOfSlist(idslist);

% 計算準備
rephss = zeros(nrephss,5);
rephss(idrephss2slist==idslist,1:2) = ...
  xvar(idrephss2v(idrephss2slist==idslist,1:2));
id.slist = zeros(nrephss,1);
id.section = zeros(nrephss,1);

% 断面の検索
for id_=1:nrephss

  % 断面と断面リストが対応しないときはスキップ
  if idrephss2slist(id_)~=idslist
    continue
  end

  % 適合断面の抽出
  % idhss = idrephss2hss(id_);
  % isvalid_ = isvalid(idhss,:);
  isvalid_ = isvalid;
  secdimlist = secdimlist_all(isvalid_,:);
  rtlist = secdimlist(:,1)./secdimlist(:,2);
  Dlist = secdimlist(:,1);
  iddd = 1:size(secdimlist,1);
  id_2id = 1:size(secdimlist_all,1); id_2id = id_2id(isvalid_);

  % 完全一致なら検索不要
  isok = rephss(id_,1)==secdimlist(:,1)&rephss(id_,2)==secdimlist(:,2);
  if any(isok)
    idfound = iddd(isok);

    % 断面の保存
    if(length(idfound)>1)
      idfound=idfound(1);
    end
    for j=1:3
      rephss(id_,j) = secdimlist(idfound,j);
    end
    id.slist(id_) = idslist;
    id.section(id_) = id_2id(idfound);
    continue
  end

  % --- ユークリッド距離が最小となる断面の選択 ---
  % [~, idlist] = pdist2(slist(:,1:2), rephss(id,1:2),...
  %     'fastsquaredeuclidean','Smallest',1);
  % sss = slist(idlist,:);

  % --- 幅厚比距離が最小となる断面の選択 ---
  % xvarからDiの取り出し
  idD = idrephss2v(id_,1);
  Di = xvar(idD);

  % Diに最も近いDを採用
  ddd = abs(Dlist-Di);
  [~, idfound] = min(ddd);
  rephss(id_,1) = Dlist(idfound);

  % Dを固定し，最も近いtを検索
  % Diに適合する規格断面のチェック
  isGiven = abs(Dlist-rephss(id_,1))<=options.tolDgap;

  if any(isGiven)
    % 該当断面あり->最小距離断面の選択
    rt = rephss(id_,1)./rephss(id_,2);
    ddd = (rtlist-rt).^2;
    [~, idl_] = min(ddd(isGiven));
    % sss = slistdim(isGiven,:);
    % sss = sss(idl,:);
    iii = iddd(isGiven);
    idfound = iii(idl_);
    sss = secdimlist(idfound,:);
  else
    % 該当断面なし
    sss = secdimlist(idfound,:);
  end
    
  % 断面の保存
  for j=1:3
    rephss(id_,j) = sss(j);
  end
  id.slist(id_) = idslist;
  id.section(id_) = id_2id(idfound);
end
sechss = rephss(idhss2rephss,:);
id.slist = id.slist(idhss2rephss);
id.section = id.section(idhss2rephss);

return
end


