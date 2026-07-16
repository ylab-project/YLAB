function [xlist, sdlist] = findNearestXList( ...
  obj, xlist0, options, initial_guess, com_constant)
%findNearestXList - 変数リストを最近傍断面へ写像する
%
%   [xlist, sdlist] = findNearestXList(obj, xlist0, options,
%   initial_guess, com_constant) は、各候補を最近傍規格断面へ写像し、
%   写像後の変数と断面寸法を返す。
%
%   入力引数:
%     obj           - SectionNeighborSearcherインスタンス
%     xlist0        - 変数値リスト [nlist×nxvar]
%     options       - 共通オプション
%     initial_guess - 共通基点（.x、.secdim）。省略可能
%     com_constant  - worker配布済みcom。省略可能
%
%   出力引数:
%     xlist  - 写像後の変数値リスト [nlist×nxvar]
%     sdlist - 写像済み断面寸法 [nsec×7×nlist]

if nargin < 4
  initial_guess = [];
end
if nargin < 5
  com_constant = [];
end
[nlist, ncols] = size(xlist0);
do_parallel = nlist > 1 && isfield(options, 'do_parallel') && ...
  options.do_parallel;
use_constant = do_parallel && ...
  isa(com_constant, 'parallel.pool.Constant');
xlist = zeros(nlist, ncols);
sdlist = zeros(size(obj.dimension_, 1), PRM.MAPPED_SECDIM_NCOL, nlist);

if use_constant
  parfor id = 1:nlist
    worker_com = com_constant.Value; %#ok<PFBNS>
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