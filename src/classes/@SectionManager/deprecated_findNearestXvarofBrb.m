function xvar = deprecated_findNearestXvarofBrb(secmgr, repbrbs, xvar0, options)
%deprecated_findNearestXvarofBrb BRB断面の最近傍変数値を検索（非推奨）
%   このメソッドは非推奨です。
%   代わりに neighborSearcher.findNearestXvarofBrb を使用してください。
%
%   xvar = deprecated_findNearestXvarofBrb(secmgr, repbrbs, xvar0, options) は、
%   BRB断面の代表断面から最近傍の変数値を検索します。

% 非推奨警告
warning('SectionManager:deprecated', ...
  ['deprecated_findNearestXvarofBrb は非推奨です。' ...
   '代わりに neighborSearcher.findNearestXvarofBrb ' ...
   'を使用してください。']);

% 共通配列
idv1_var = secmgr.idBrb1_var(:)';
idv2_var = secmgr.idBrb2_var(:)';
idvar2srep = secmgr.idvar2srep;
idsrep2stype = secmgr.idsrep2stype;

% 共通定数
nsrep = secmgr.nsrep;
nrepbrbs = secmgr.nrepbrbs;
nxvar = secmgr.nxvar;

% 計算の準備
if isempty(xvar0)
  xvar = zeros(1,nxvar);
else
  xvar = xvar0;
end
idsrep2repbrbs = zeros(nsrep,1);
idsrep2repbrbs(idsrep2stype==PRM.BRB) = 1:nrepbrbs;
isVarofSlist = secmgr.isVarofSlist;

for idlist = 1:secmgr.nlist
  if secmgr.secList.section_type(idlist)~=PRM.BRB
    % 対象リストでなければスキップ
    continue
  end

  % 断面リストの読み出し
  secdimlist = secmgr.getDimension(idlist);
  v0list = unique(secdimlist(:,1));
  v1list = unique(secdimlist(:,2));
  v2list = unique(secdimlist(:,3));

  % TODO: v0でBRBの種別を分類するが現在はUBBのみで場合分けしていない
  for iv1 = idv1_var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(iv1,idlist)
      continue
    end
    % v1(Ny)の検索
    iddd = idsrep2repbrbs(idvar2srep{iv1});
    iddd = iddd(iddd>0);
    iddd = iddd(1); % とりあえず
    v1set = repbrbs(iddd,2);
    ddd = mean(pdist2(v1list,v1set,'fasteuclidean'),2);
    [~, id] = min(ddd);
    v1i = v1list(id);
    xvar(iv1) = v1i;
  end

  for iv2 = idv2_var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(iv2,idlist)
      continue
    end
    % v2(SubID)の検索
    iddd = idsrep2repbrbs(idvar2srep{iv2});
    iddd = iddd(iddd>0);
    iddd = iddd(1); % とりあえず
    v2set = repbrbs(iddd,3);
    ddd = mean(pdist2(v2list,v2set,'fasteuclidean'),2);
    [~, id] = min(ddd);
    v2i = v2list(id);
    xvar(iv2) = v2i;
  end
end

return
end