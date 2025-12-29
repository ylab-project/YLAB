function xvar = deprecated_findNearestXvarofHss(secmgr, rephss, xvar0, options)
%deprecated_findNearestXvarofHss HSS断面の最近傍変数値を検索（非推奨）
%   このメソッドは非推奨です。
%   代わりに neighborSearcher.findNearestXvarofHss を使用してください。
%
%   xvar = deprecated_findNearestXvarofHss(secmgr, rephss, xvar0, options) は、
%   HSS断面の代表断面から最近傍の変数値を検索します。

% 非推奨警告
warning('SectionManager:deprecated', ...
  ['deprecated_findNearestXvarofHss は非推奨です。' ...
   '代わりに neighborSearcher.findNearestXvarofHss ' ...
   'を使用してください。']);

% 共通配列
idD2var = secmgr.idD2var(:)';
idt2var = secmgr.idt2var(:)';
idvar2srep = secmgr.idvar2srep;
idsrep2stype = secmgr.idsrep2stype;

% 共通定数
nsrep = secmgr.nsrep;
nrephss = secmgr.nrephss;
nxvar = secmgr.nxvar;

% 計算の準備
if isempty(xvar0)
  xvar = zeros(1,nxvar);
else
  xvar = xvar0;
end
idsrep2rephss = zeros(nsrep,1);
idsrep2rephss(idsrep2stype==PRM.HSS) = 1:nrephss;
isVarofSlist = secmgr.isVarofSlist;

for idlist = 1:secmgr.nlist
  if secmgr.secList.section_type(idlist)~=PRM.HSS
    % 対象リストでなければスキップ
    continue
  end

  % 断面リストの読み出し
  secdimlist = secmgr.getDimension(idlist);
  Dlist = unique(secdimlist(:,1));
  tlist = unique(secdimlist(:,2));

  for ivD = idD2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivD,idlist)
      continue
    end
    % Dの検索
    iddd = idsrep2rephss(idvar2srep{ivD});
    iddd = iddd(iddd>0);
    Dset = rephss(iddd,1);
    ddd = mean(pdist2(Dlist,Dset,'fasteuclidean'),2);
    [~, id] = min(ddd);
    Di = Dlist(id);
    xvar(ivD) = Di;
  end

  for ivt = idt2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivt,idlist)
      continue
    end
    % tの検索
    iddd = idsrep2rephss(idvar2srep{ivt});
    iddd = iddd(iddd>0);
    tset = rephss(iddd,2);
    ddd = mean(pdist2(tlist,tset,'fasteuclidean'),2);
    [~, id] = min(ddd);
    ti = tlist(id);
    xvar(ivt) = ti;
  end
end

return
end