function xvar = deprecated_findNearestXvarofWfs(secmgr, repwfs, xvar0, options)
%deprecated_findNearestXvarofWfs WFS断面の最近傍変数値を検索（非推奨）
%   このメソッドは非推奨です。
%   代わりに neighborSearcher.findNearestXvarofWfs を使用してください。
%
%   xvar = deprecated_findNearestXvarofWfs(secmgr, repwfs, xvar0, options) は、
%   WFS断面の代表断面から最近傍の変数値を検索します。

% 非推奨警告
warning('SectionManager:deprecated', ...
  ['deprecated_findNearestXvarofWfs は非推奨です。' ...
   '代わりに neighborSearcher.findNearestXvarofWfs ' ...
   'を使用してください。']);

% 共通配列
idH2var = secmgr.idH2var(:)';
idB2var = secmgr.idB2var(:)';
idtw2var = secmgr.idtw2var(:)';
idtf2var = secmgr.idtf2var(:)';
idvar2srep = secmgr.idvar2srep;
idsrep2stype = secmgr.idsrep2stype;

% 共通定数
nsrep = secmgr.nsrep;
nrepwfs = secmgr.nrepwfs;
nxvar = secmgr.nxvar;

% 計算の準備
if isempty(xvar0)
  xvar = zeros(1,nxvar);
else
  xvar = xvar0;
end
idsrep2repwfs = zeros(nsrep,1);
idsrep2repwfs(idsrep2stype==PRM.WFS) = 1:nrepwfs;
isVarofSlist = secmgr.isVarofSlist;

for idlist = 1:secmgr.nlist
  if secmgr.secList.section_type(idlist)~=PRM.WFS
    % 対象リストでなければスキップ
    continue
  end  

  % 断面リストの読み出し
  % slist = secmgr.secList.getDimension(idlist);
  secdimlist = secmgr.getDimension(idlist);
  Hnom = secmgr.getHnominal(idlist)';
  Bnom = secmgr.getBnominal(idlist)';
  twlist = unique(secdimlist(:,3));
  tflist = unique(secdimlist(:,4));

  for ivH = idH2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivH,idlist)
      continue
    end
    % Hの検索
    Hset = repwfs(idsrep2repwfs(idvar2srep{ivH}),1);
    ddd = mean(pdist2(Hnom,Hset,'fasteuclidean'),2);
    [~, id] = min(ddd);
    Hi = Hnom(id);
    xvar(ivH) = Hi;
  end

  for ivB = idB2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivB,idlist)
      continue
    end
    % Bの検索
    Bset = repwfs(idsrep2repwfs(idvar2srep{ivB}),2);
    ddd = mean(pdist2(Bnom,Bset,'fasteuclidean'),2);
    [~, id] = min(ddd);
    Bi = Bnom(id);
    xvar(ivB) = Bi;
  end

  for ivtw = idtw2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivtw,idlist)
      continue
    end
    % twの検索
    twset = repwfs(idsrep2repwfs(idvar2srep{ivtw}),3);
    ddd = mean(pdist2(twlist,twset,'fasteuclidean'),2);
    [~, id] = min(ddd);
    twi = twlist(id);
    xvar(ivtw) = twi;
  end

  for ivtf = idtf2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivtf,idlist)
      continue
    end
    % tfの検索
    tfset = repwfs(idsrep2repwfs(idvar2srep{ivtf}),4);
    ddd = mean(pdist2(tflist,tfset,'fasteuclidean'),2);
    [~, id] = min(ddd);
    tfi = tflist(id);
    xvar(ivtf) = tfi;
  end
end

return
end