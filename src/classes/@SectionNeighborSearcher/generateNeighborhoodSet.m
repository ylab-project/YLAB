function [xlist, idvlist, sdlist] = generateNeighborhoodSet( ...
  obj, xvar, isvar, options, initial_guess, com_constant)
%generateNeighborhoodSet - 近傍断面集合を生成
%
%   [xlist, idvlist, sdlist] = generateNeighborhoodSet(...
%     obj, xvar, isvar, options, initial_guess, com_constant) は、
%   指定された変数値から近傍断面の集合を生成する。
%
%   入力引数:
%     obj           - SectionNeighborSearcherインスタンス
%     xvar          - 現在の変数値 [1×nxvar]
%     isvar         - 変数の有効フラグ [nxvar×1]
%     options       - 共通オプション
%     initial_guess - 共通基点（.x、.secdim）。省略可能
%     com_constant  - worker配布済みcom。省略可能
%
%   出力引数:
%     xlist   - 近傍断面の変数値リスト [nlist×nxvar]
%     idvlist - 変数IDリスト [nlist×1]
%               正: 上方向の変更、負: 下方向の変更、0: 現在値
%     sdlist  - 最近傍断面の寸法リスト [nsec×ndim×nlist]
%
%   参考:
%     enumerateNeighborH, enumerateNeighborB, enumerateNeighborTw,
%     enumerateNeighborTf, enumerateNeighborD, enumerateNeighborT

if nargin < 5
  initial_guess = [];
end
if nargin < 6
  com_constant = [];
end

% 変数タイプ配列を取得
vtype = obj.idMapper_.idvar2vtype;

% 計算の準備
nvar = obj.idMapper_.nxvar;
nx = length(xvar);

% 各変数ごとの近傍断面を格納するセル配列
xcell = cell(nvar, 1);
idvlist_ = struct('up', [], 'dw', []);
idvlist_(1:nvar) = struct('up', [], 'dw', []);

% 並列処理フラグの確認（デフォルトはfalse）
do_parallel = isfield(options, 'do_parallel') && options.do_parallel;
use_constant = do_parallel && isa(com_constant, 'parallel.pool.Constant');

% worker配布済みcom、通常の並列処理、逐次処理を切り替える。
if use_constant
  parfor idvar = 1:nvar
    worker_com = com_constant.Value; %#ok<PFBNS>
    worker_searcher = worker_com.secmgr.neighborSearcher;
    if ~isvar(idvar)
      xcell{idvar} = xvar;
      continue
    end

    [xlist_, idvlist_current] = enumerate_neighbor( ...
      worker_searcher, xvar, idvar, vtype(idvar), options);
    xcell{idvar} = xlist_;
    idvlist_(idvar) = idvlist_current;
  end
elseif do_parallel
  parfor idvar = 1:nvar
    if ~isvar(idvar)
      xcell{idvar} = xvar;
      continue
    end

    [xlist_, idvlist_current] = enumerate_neighbor( ...
      obj, xvar, idvar, vtype(idvar), options);
    xcell{idvar} = xlist_;
    idvlist_(idvar) = idvlist_current;
  end
else
  for idvar = 1:nvar
    if ~isvar(idvar)
      xcell{idvar} = xvar;
      continue
    end

    [xlist_, idvlist_current] = enumerate_neighbor( ...
      obj, xvar, idvar, vtype(idvar), options);
    xcell{idvar} = xlist_;
    idvlist_(idvar) = idvlist_current;
  end
end

% 結果の整理（Cell配列結合方式に最適化）
% 有効な変数のみ抽出
valid_vars = find(isvar);
xcell_valid = xcell(valid_vars);

% xlistをCell配列結合で生成（62%高速化）
if ~isempty(xcell_valid)
  xlist = vertcat(xcell_valid{:});

  % idvlistの生成
  idvlist_cells = cell(length(valid_vars), 1);
  for idx = 1:length(valid_vars)
    idvar = valid_vars(idx);
    ne = size(xcell{idvar}, 1);
    vvv = idvar * ones(ne, 1);
    % 下方向の情報を負値に変更
    if ~isempty(idvlist_(idvar).dw)
      vvv(idvlist_(idvar).dw) = -vvv(idvlist_(idvar).dw);
    end
    idvlist_cells{idx} = vvv;
  end
  idvlist = vertcat(idvlist_cells{:});
else
  xlist = zeros(0, nx);
  idvlist = zeros(0, 1);
end

% 現在値を先頭に追加
xlist = [xvar; xlist];
idvlist = [0; idvlist];

% 重複を削除
[xlist, ia] = unique(xlist, 'rows', 'stable');
idvlist = idvlist(ia);

% 最近傍断面に調整し、同じ写像で得た断面寸法を保持
[xlist, sdlist] = obj.findNearestXList(xlist, options, ...
  initial_guess, com_constant);

return
end

%--------------------------------------------------------------------------
function [xlist, idvlist] = enumerate_neighbor(searcher, xvar, ...
  idvar, vtype_id, options)
%enumerate_neighbor - 変数種別に応じた近傍断面を列挙
%
%   [xlist, idvlist] = enumerate_neighbor(searcher, xvar, idvar,
%     vtype_id, options) は、指定した変数種別に対応する列挙メソッドを
%   呼び出し、近傍断面と上下方向の行番号を返す。
%
%   入力引数:
%     searcher - SectionNeighborSearcherインスタンス
%     xvar     - 現在の変数値 [1×nxvar]
%     idvar    - 列挙対象の変数ID
%     vtype_id - 列挙対象の変数種別
%     options  - 共通オプション
%
%   出力引数:
%     xlist   - 列挙した近傍断面の変数値リスト
%     idvlist - 上下方向の行番号（.up、.dw）

xlist = [];
idvlist = struct('up', [], 'dw', []);
switch vtype_id
  case PRM.WFS_H
    [xlist, ~, ~, idvlist] = searcher.enumerateNeighborH( ...
      xvar, idvar, options);
  case PRM.WFS_B
    [xlist, ~, ~, idvlist] = searcher.enumerateNeighborB( ...
      xvar, idvar, options);
  case PRM.WFS_TW
    [xlist, ~, ~, ~, idvlist] = searcher.enumerateNeighborTw( ...
      xvar, idvar, options);
  case PRM.WFS_TF
    [xlist, ~, ~, ~, idvlist] = searcher.enumerateNeighborTf( ...
      xvar, idvar, options);
  case PRM.HSS_D
    [xlist, ~, ~, idvlist] = searcher.enumerateNeighborD( ...
      xvar, idvar, options);
  case PRM.HSS_T
    [xlist, ~, ~, ~, idvlist] = searcher.enumerateNeighborT( ...
      xvar, idvar, options);
  case PRM.BRB_V1
    [xlist, ~, ~, idvlist] = searcher.enumerateBrbV1( ...
      xvar, idvar, options);
  case PRM.BRB_V2
    [xlist, ~, ~, idvlist] = searcher.enumerateBrbV2( ...
      xvar, idvar, options);
end

return
end