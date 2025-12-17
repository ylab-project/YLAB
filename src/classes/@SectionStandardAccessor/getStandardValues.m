function [stvals, stnum] = getStandardValues(obj)
%getStandardValues 全断面リストの規格値セットを取得
%   [stvals, stnum] = getStandardValues(obj) は、
%   GA最適化で使用する全断面の規格値を統合して返します。
%
%   出力引数:
%     stvals - 規格値配列 [nxvar×max(stnum)] NaN埋め
%     stnum - 各変数の規格値数 [nxvar×1]
%
%   例:
%     [vals, nums] = accessor.getStandardValues();
%
%   参考:
%     getNominalH, getNominalB, getStandardTw, getStandardTf,
%     getStandardD, getStandardT

% PRM定数から変数タイプセットを取得
vtypeset = [PRM.WFS_H PRM.WFS_B PRM.WFS_TW PRM.WFS_TF ...
            PRM.HSS_D PRM.HSS_T];
nxvar = obj.idMapper_.nxvar;

% 各変数タイプごとに効率的な値収集
allUniqueValues = cell(length(vtypeset), 1);
for i = 1:length(vtypeset)
  vtype = vtypeset(i);
  
  % cell配列で各断面リストの値を収集
  collectedCells = cell(obj.nlist, 1);
  validCount = 0;
  
  for id = 1:obj.nlist
    switch vtype
      case PRM.WFS_H
        vals = obj.getNominalH(id);
      case PRM.WFS_B
        vals = obj.getNominalB(id);
      case PRM.WFS_TW
        vals = obj.getStandardTw(id);
      case PRM.WFS_TF
        vals = obj.getStandardTf(id);
      case PRM.HSS_D
        vals = obj.getStandardD(id);
      case PRM.HSS_T
        vals = obj.getStandardT(id);
    end
    
    if ~isempty(vals)
      validCount = validCount + 1;
      collectedCells{validCount} = vals;
    end
  end
  
  % cell配列を効率的に連結してから1回だけunique
  if validCount > 0
    allVals = [collectedCells{1:validCount}];
    allUniqueValues{i} = unique(allVals);
  else
    allUniqueValues{i} = [];
  end
end

% 変数マッピングと行列変換
[stvals, stnum] = mapToVariables(obj, allUniqueValues, vtypeset);

return
end

%% mapToVariables
function [stvals, stnum] = mapToVariables(obj, allUniqueValues, vtypeset)
%mapToVariables 変数マッピングと行列変換
%   変数タイプの値を適切な変数インデックスにマッピングし、
%   NaN埋めの行列形式に変換します。

nxvar = obj.idMapper_.nxvar;
stvals = cell(nxvar, 1);

% 変数マッピング情報を取得
isVarofSlist = obj.idMapper_.getIsVarofSlist();
idvar2vtype = obj.idMapper_.idvar2vtype;

% 各変数タイプの値を適切な変数インデックスにマッピング
for i = 1:length(vtypeset)
  vtype = vtypeset(i);
  values = allUniqueValues{i};
  
  if isempty(values)
    continue
  end
  
  % この変数タイプに対応する変数を検索
  for id = 1:obj.nlist
    istarget = isVarofSlist(:, id) & idvar2vtype == vtype;
    if any(istarget)
      idtarget = find(istarget);
      for j = idtarget'
        stvals{j} = unique([stvals{j} values]);
      end
    end
  end
end

% 規格値数の計算
stnum = zeros(nxvar, 1);
for i = 1:nxvar
  if ~isempty(stvals{i})
    stnum(i) = length(stvals{i});
  end
end

% 行列に変換（NaN埋め）
m = max(stnum);
if m == 0
  stvals = [];
  return
end

tmp = stvals;
stvals = nan(nxvar, m);
for i = 1:nxvar
  if stnum(i) > 0
    stvals(i, 1:stnum(i)) = tmp{i};
  end
end

return
end