function xlist = findNearestXList_optimized(obj, xlist0, options)
%findNearestXList_optimized 変数リストから最近傍断面を選択（最適化版）
%   xlist = findNearestXList_optimized(obj, xlist0, options) は、
%   変数値リストの各要素について最近傍の規格断面を選択します。
%   必要最小限のオブジェクトを定数化して効率化します。
%
%   入力引数:
%     xlist0  - 変数値リスト [nlist×nxvar]
%     options - オプション構造体
%
%   出力引数:
%     xlist   - 最近傍断面の変数値リスト [nlist×nxvar]

% 共通処理：サイズ取得と初期化
[nlist, ncols] = size(xlist0);

% 並列処理の判定
if nlist == 1
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end

% 出力配列の事前確保
xlist = zeros(nlist, ncols);

if do_parallel
  % 並列処理最適化：必要なデータを定数化して静的メソッドを使用
  
  % 主要なオブジェクトを定数化
  const_idMapper = parallel.pool.Constant(obj.idMapper_);
  const_standardAccessor = parallel.pool.Constant(obj.standardAccessor_);
  const_dimension = parallel.pool.Constant(obj.dimension_);
  const_constraintValidator = parallel.pool.Constant(obj.constraintValidator_);
  
  % 各断面リストのデータを事前に取得
  nlist_sections = obj.standardAccessor_.nlist;
  secListAll = cell(nlist_sections, 1);
  for idslist = 1:nlist_sections
    secListCell = struct();
    secListCell.secdim = obj.standardAccessor_.getSectionDimension(idslist);
    secListAll{idslist} = secListCell;
  end
  const_secListAll = parallel.pool.Constant(secListAll);
  
  parfor id = 1:nlist
    xvar = xlist0(id, :);
    
    % 修正版の静的メソッドを使用
    secdim = SectionNeighborSearcher.findNearestSectionStatic_fixed(...
      xvar, options, ...
      const_idMapper.Value, ...
      const_standardAccessor.Value, ...
      const_dimension.Value, ...
      const_secListAll.Value, ...
      const_constraintValidator.Value);
    
    xlist(id, :) = SectionNeighborSearcher.findNearestXvarStatic(...
      secdim, options, ...
      const_idMapper.Value);
  end
else
  % 逐次処理（変更なし）
  for id = 1:nlist
    xvar = xlist0(id, :);
    secdim = obj.findNearestSection(xvar, options);
    xlist(id, :) = obj.findNearestXvar(secdim, options);
  end
end

return
end