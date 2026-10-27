function sdlist = findNearestSectionList(obj, xlist, options, ...
  initial_guess, com)
%findNearestSectionList - 候補の設計変数から規格断面を一括選択する
%
%   sdlist = findNearestSectionList(obj, xlist, options,
%     initial_guess, com) は、各候補の設計変数を保持したまま、
%   対応する規格断面だけを選択する。
%
%   入力引数:
%     obj - SectionNeighborSearcherインスタンス
%     xlist - 候補の設計変数 [nlist×nxvar]
%     options - 共通オプション
%     initial_guess - 基点の設計変数と断面。省略可能
%     com - workerへ配布する共通データ。省略可能
%
%   出力引数:
%     sdlist - 各候補から選択した断面寸法 [nsec×7×nlist]

if nargin < 4
  initial_guess = [];
end
if nargin < 5
  com = [];
end
nlist = size(xlist, 1);
sdlist = zeros(size(obj.dimension_, 1), PRM.MAPPED_SECDIM_NCOL, nlist);
do_parallel = nlist > 1 && options.do_parallel;
use_worker_cache = do_parallel && isstruct(com) && isfield(com, ...
  'constant') && isa(com.constant, 'parallel.pool.Constant');
if use_worker_cache
  worker_com_cache = com.constant;
  parfor id = 1:nlist
    worker_com = worker_com_cache.Value; %#ok<PFBNS>
    sdlist(:, :, id) = worker_com.secmgr.findNearestSection( ...
      xlist(id, :), options, initial_guess);
  end
elseif do_parallel
  parfor id = 1:nlist
    sdlist(:, :, id) = obj.findNearestSection( xlist(id, :), options, ...
      initial_guess); %#ok<PFBNS>
  end
else
  for id = 1:nlist
    sdlist(:, :, id) = obj.findNearestSection( xlist(id, :), options, ...
      initial_guess);
  end
end

return
end
