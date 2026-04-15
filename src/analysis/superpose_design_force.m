function dfn = superpose_design_force(dfn0, lcdir, is_girder, n_beam)
%superpose_design_force - 解析（荷重）ケースの重ね合わせ
%
%   長期ケース(G+P)を複製し、地震時ケース(EX±/EY±)を
%   短期組合せ（長期＋地震時）として上書きする。
%   梁の設計用せん断力については、設計ルート由来の割増率 n を
%   地震時成分にのみ適用する: Q_D = Q_L + n*Q_E。
%
%   Inputs:
%     dfn0     - 組合せ前応力 [nnm x ncomp x nlc]
%     lcdir    - 荷重ケース方向 [nlc]
%     is_girder - 梁の行マスク [nnm x 1]（省略可）
%     n_beam   - 梁Qに適用する割増率（省略時=1.0）
%
%   Outputs:
%     dfn - 短期重ね合わせ後の応力 [nnm x ncomp x nlc]

% 定数
[~, ~, nlc] = size(dfn0);

% 既定引数
if nargin < 3
  is_girder = [];
end
if nargin < 4 || isempty(n_beam)
  n_beam = 1.0;
end

dfn = dfn0;

% 長期
for ilc = 1:nlc
  if lcdir(ilc)==PRM.LT
    dfn(:,:,1) = dfn0(:,:,ilc);
  end
end

% 短期 = 長期＋地震時
for ilc = 1:nlc
  switch lcdir(ilc)
    case PRM.EXP
      id = PRM.EXP;
    case PRM.EXN
      id = PRM.EXN;
    case PRM.EYP
      id = PRM.EYP;
    case PRM.EYN
      id = PRM.EYN;
    otherwise
      continue
  end

  % 通常の重ね合わせ
  dfn(:,:,id) = dfn0(:,:,ilc)+dfn(:,:,1);

  % 梁Q(index 3, 9) のみ n_beam を地震時成分に適用
  if n_beam ~= 1.0 && ~isempty(is_girder) && any(is_girder)
    dfn(is_girder, [3 9], id) = dfn(is_girder, [3 9], 1) ...
      + n_beam * dfn0(is_girder, [3 9], ilc);
  end
end
return
end
