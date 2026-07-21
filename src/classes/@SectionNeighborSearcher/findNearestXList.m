function [xlist, sdlist] = findNearestXList( ...
  obj, xlist0, options, initial_guess, com)
%findNearestXList - 変数リストを最近傍断面へ写像する
%
%   [xlist, sdlist] = findNearestXList(obj, xlist0, options,
%   initial_guess, com) は、各候補を最近傍規格断面へ写像し、
%   写像後の変数と断面寸法を返す。
%
%   入力引数:
%     obj           - SectionNeighborSearcherインスタンス
%     xlist0        - 変数値リスト [nlist×nxvar]
%     options       - 共通オプション
%     initial_guess - 共通基点（.x、.secdim）。省略可能
%     com           - worker用constantを持つ共通構造体。省略可能
%
%   出力引数:
%     xlist  - 写像後の変数値リスト [nlist×nxvar]
%     sdlist - 写像済み断面寸法 [nsec×7×nlist]

if nargin < 4
  initial_guess = [];
end
if nargin < 5
  com = [];
end
[nlist, ncols] = size(xlist0);
do_parallel = nlist > 1 && isfield(options, 'do_parallel') && ...
  options.do_parallel;
use_worker_cache = do_parallel && isstruct(com) && ...
  isfield(com, 'constant') && ...
  isa(com.constant, 'parallel.pool.Constant');
xlist = zeros(nlist, ncols);
sdlist = zeros(size(obj.dimension_, 1), PRM.MAPPED_SECDIM_NCOL, nlist);

if use_worker_cache
  worker_com_cache = com.constant;
  parfor id = 1:nlist
    worker_com = worker_com_cache.Value; %#ok<PFBNS>
    worker_secmgr = worker_com.secmgr;
    secdim = worker_secmgr.findNearestSection( ...
      xlist0(id, :), options, initial_guess);
    sdlist(:, :, id) = secdim;
    xlist(id, :) = worker_secmgr.findNearestXvar( ...
      secdim, options, initial_guess);
  end
elseif do_parallel
  parfor id = 1:nlist
    secdim = obj.findNearestSection( ...
      xlist0(id, :), options, initial_guess); %#ok<PFBNS>
    sdlist(:, :, id) = secdim;
    xlist(id, :) = obj.findNearestXvar( ...
      secdim, options, initial_guess);
  end
else
  for id = 1:nlist
    secdim = obj.findNearestSection( ...
      xlist0(id, :), options, initial_guess);
    sdlist(:, :, id) = secdim;
    xlist(id, :) = obj.findNearestXvar( ...
      secdim, options, initial_guess);
  end
end

return
end