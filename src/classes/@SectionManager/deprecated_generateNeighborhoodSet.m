function [xlist, idvlist] = ...
  deprecated_generateNeighborhoodSet(secmgr, xvar, isvar, options)
%deprecated_generateNeighborhoodSet 近傍断面集合の生成（非推奨）
%   このメソッドは非推奨です。
%   代わりに neighborSearcher.generateNeighborhoodSet を使用してください。
%
%   [xlist, idvlist] = deprecated_generateNeighborhoodSet(secmgr, xvar, 
%     isvar, options) は、指定された変数値から近傍断面の集合を生成します。
%
%   入力引数:
%     xvar    - 現在の変数値 [1×nxvar]
%     isvar   - 変数の有効フラグ [nxvar×1] 論理値配列
%     options - オプション構造体
%
%   出力引数:
%     xlist   - 近傍断面の変数値リスト [nlist×nxvar]
%     idvlist - 変数IDリスト [nlist×1]
%
%   参考:
%     SectionNeighborSearcher.generateNeighborhoodSet

% 非推奨警告
warning('SectionManager:deprecated', ...
  ['deprecated_generateNeighborhoodSet は非推奨です。' ...
   '代わりに neighborSearcher.generateNeighborhoodSet ' ...
   'を使用してください。']);

% 共通配列
% idvH = secmgr.idH2var';
% idvB = secmgr.idB2var';
% idvtw = secmgr.idtw2var';
% idvtf = secmgr.idtf2var';
% idvD = secmgr.idD2var';
% idvt = secmgr.idt2var';
vtype = secmgr.idvar2vtype;

% 計算の準備
nvar = secmgr.nxvar;
nx = length(xvar);
max_xlist = 1000;
% icount = 0;
% xlist = zeros(max_xlist, nx);

% % 現在値を追加
% add_to_xlist(xvar);
%
% H形鋼 -> Hの近傍断面
xcell = cell(nvar,1);
idvlist_(1:nvar) = struct('up',[],'dw',[]);

% 並列処理フラグの確認（デフォルトはfalse）
do_parallel = isfield(options, 'do_parallel') && options.do_parallel;

if do_parallel
  parfor idvar = 1:nvar
    xlist_ = [];
    if ~isvar(idvar)
      xlist_ = xvar;
      xcell{idvar} = xlist_;
      continue
    end
    switch vtype(idvar)
      case PRM.WFS_H
        % H形鋼 -> Hの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborH(xvar, idvar, options);
      case PRM.WFS_B
        % H形鋼 -> Bの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborB(xvar, idvar, options);
      case PRM.WFS_TW
        % H形鋼 -> twの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborTw(xvar, idvar, options);
      case PRM.WFS_TF
        % H形鋼 -> tfの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)]  = ...
          secmgr.deprecated_enumerateNeighborTf(xvar, idvar, options);
      case PRM.HSS_D
        % 角形鋼管 -> Dの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborD(xvar, idvar, options);
      case PRM.HSS_T
        % 角形鋼管 -> tの近傍断面
        [xlist_ , ~, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborT(xvar, idvar, options);
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
    switch vtype(idvar)
      case PRM.WFS_H
        % H形鋼 -> Hの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborH(xvar, idvar, options);
      case PRM.WFS_B
        % H形鋼 -> Bの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborB(xvar, idvar, options);
      case PRM.WFS_TW
        % H形鋼 -> twの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborTw(xvar, idvar, options);
      case PRM.WFS_TF
        % H形鋼 -> tfの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborTf(xvar, idvar, options);
      case PRM.HSS_D
        % 角形鋼管 -> Dの近傍断面
        [xlist_, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborD(xvar, idvar, options);
      case PRM.HSS_T
        % 角形鋼管 -> tの近傍断面
        [xlist_, ~, ~, ~, idvlist_(idvar)] = ...
          secmgr.deprecated_enumerateNeighborT(xvar, idvar, options);
    end
    xcell{idvar} = xlist_;
  end
end

% 結果の整理
nlist = 0;
xlist = zeros(max_xlist, nx);
idvlist = zeros(max_xlist,1);

for idvar=1:nvar
  if ~isvar(idvar)
    continue
  end
  ne = size(xcell{idvar},1);

  % xlist
  xlist(nlist+1:nlist+ne,:) = xcell{idvar};

  % idvlist
  vvv = idvar*ones(1,ne);
  vvv(idvlist_(idvar).dw) = -vvv(idvlist_(idvar).dw);
  idvlist(nlist+1:nlist+ne) = vvv;
  nlist = nlist+ne;
end

xlist = [xvar; xlist(1:nlist,:)];
idvlist = [0; idvlist(1:nlist)];
[xlist, ia] = unique(xlist,'rows','stable');
idvlist = idvlist(ia);
xlist = secmgr.findNearestXList(xlist, options);

return
end