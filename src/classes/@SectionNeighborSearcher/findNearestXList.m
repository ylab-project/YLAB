function xlist = findNearestXList(obj, xlist0, options)
%findNearestXList 変数リストから最近傍断面を選択
%   xlist = findNearestXList(obj, xlist0, options) は、
%   変数値リストの各要素について最近傍の規格断面を選択します。
%
%   入力引数:
%     xlist0  - 変数値リスト [nlist×nxvar]
%     options - オプション構造体
%
%   出力引数:
%     xlist   - 最近傍断面の変数値リスト [nlist×nxvar]

[nlist, ncols] = size(xlist0);

% 並列処理の判定
if nlist == 1
  do_parallel = false;
else
  do_parallel = isfield(options, 'do_parallel') && options.do_parallel;
end

% 出力配列の事前確保
xlist = zeros(nlist, ncols);

if do_parallel
  parfor id = 1:nlist
    xvar = xlist0(id, :);
    secdim = obj.findNearestSection(xvar, options);
    xlist(id, :) = obj.findNearestXvar(secdim, options);
  end
else
  for id = 1:nlist
    xvar = xlist0(id, :);
    secdim = obj.findNearestSection(xvar, options);
    xlist(id, :) = obj.findNearestXvar(secdim, options);
  end
end

return
end