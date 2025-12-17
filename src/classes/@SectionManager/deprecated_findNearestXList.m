function xlist = deprecated_findNearestXList(secmgr, xlist, options)
%deprecated_findNearestXList 変数リストから最近傍断面を選択（非推奨）
%   このメソッドは非推奨です。
%   代わりに neighborSearcher.findNearestXList を使用してください。
%
%   xlist = deprecated_findNearestXList(secmgr, xlist, options) は、
%   変数値リストの各要素について最近傍の規格断面を選択します。

% 非推奨警告
warning('SectionManager:deprecated', ...
  ['deprecated_findNearestXList は非推奨です。' ...
   '代わりに neighborSearcher.findNearestXList ' ...
   'を使用してください。']);

nlist = size(xlist,1);
% xlist0 = xlist;
sdlist = zeros(secmgr.nsec,7,nlist);
if (nlist==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end

if do_parallel
  parfor id=1:nlist
    xvar = xlist(id,:);
    secdim = secmgr.findNearestSection(xvar, options);
    xlist(id,:) = secmgr.findNearestXvar(secdim, options);
  end
else
  for id=1:nlist
    xvar = xlist(id,:);
    secdim = secmgr.findNearestSection(xvar, options);
    xlist(id,:) = secmgr.findNearestXvar(secdim, options);
    sdlist(:,:,id) = secdim;
  end
end

return
end