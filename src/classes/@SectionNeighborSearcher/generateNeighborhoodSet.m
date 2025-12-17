function [xlist, idvlist] = ...
  generateNeighborhoodSet(obj, xvar, isvar, options)
%generateNeighborhoodSet 近傍断面集合の生成
%   [xlist, idvlist] = generateNeighborhoodSet(obj, xvar, isvar, options)
%   は、指定された変数値から近傍断面の集合を生成します。
%
%   入力引数:
%     xvar    - 現在の変数値 [1×nxvar]
%     isvar   - 変数の有効フラグ [nxvar×1] 論理値配列
%     options - オプション構造体
%               .do_parallel - 並列処理の有無（既定値: false）
%
%   出力引数:
%     xlist   - 近傍断面の変数値リスト [nlist×nxvar]
%     idvlist - 変数ID リスト [nlist×1]
%               正: 上方向の変更、負: 下方向の変更、0: 現在値
%
%   参考:
%     enumerateNeighborH, enumerateNeighborB, enumerateNeighborTw,
%     enumerateNeighborTf, enumerateNeighborD, enumerateNeighborT

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

% 並列処理または逐次処理
if do_parallel
  parfor idvar = 1:nvar
    xlist_ = [];
    if ~isvar(idvar)
      xlist_ = xvar;
      xcell{idvar} = xlist_;
      continue
    end
    
    % 変数タイプに応じて適切なenumerateNeighborメソッドを呼び出し
    switch vtype(idvar)
      case PRM.WFS_H
        % H形鋼 -> Hの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborH(xvar, idvar, options);
      case PRM.WFS_B
        % H形鋼 -> Bの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborB(xvar, idvar, options);
      case PRM.WFS_TW
        % H形鋼 -> twの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborTw(xvar, idvar, options);
      case PRM.WFS_TF
        % H形鋼 -> tfの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborTf(xvar, idvar, options);
      case PRM.HSS_D
        % 角形鋼管 -> Dの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborD(xvar, idvar, options);
      case PRM.HSS_T
        % 角形鋼管 -> tの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborT(xvar, idvar, options);
    end
    xcell{idvar} = xlist_;
  end
else
  for idvar = 1:nvar
    xlist_ = [];
    if ~isvar(idvar)
      xlist_ = xvar;
      xcell{idvar} = xlist_;
      continue
    end
    
    % 変数タイプに応じて適切なenumerateNeighborメソッドを呼び出し
    switch vtype(idvar)
      case PRM.WFS_H
        % H形鋼 -> Hの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborH(xvar, idvar, options);
      case PRM.WFS_B
        % H形鋼 -> Bの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborB(xvar, idvar, options);
      case PRM.WFS_TW
        % H形鋼 -> twの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborTw(xvar, idvar, options);
      case PRM.WFS_TF
        % H形鋼 -> tfの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborTf(xvar, idvar, options);
      case PRM.HSS_D
        % 角形鋼管 -> Dの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborD(xvar, idvar, options);
      case PRM.HSS_T
        % 角形鋼管 -> tの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          obj.enumerateNeighborT(xvar, idvar, options);
    end
    xcell{idvar} = xlist_;
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

% 最近傍断面に調整
xlist = obj.findNearestXList(xlist, options);

return
end