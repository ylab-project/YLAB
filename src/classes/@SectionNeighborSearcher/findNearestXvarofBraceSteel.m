function xvar = findNearestXvarofBraceSteel(obj, secdim, ...
  is_bsteel, xvar0, recalculate_variable)
%findNearestXvarofBraceSteel - ブレース鋼材の変数値を設定
%
%   xvar = findNearestXvarofBraceSteel(obj, secdim,
%     is_bsteel, xvar0) は、ブレース鋼材断面
%   （BWFS/BHSS/BHSR）の寸法を idsec2var 経由で
%   xvar に直接設定する。
%
%   入力引数:
%     secdim    - 断面寸法データ [nsec×ndim]
%     is_bsteel - 対象断面の論理配列 [nsec×1]
%     xvar0     - 初期変数値ベクトル [1×nxvar]
%     recalculate_variable - 再計算する設計変数の論理配列
%
%   出力引数:
%     xvar - 変数値ベクトル [1×nxvar]

xvar = xvar0(:)';
idsec2var = obj.idMapper_.idsec2var;
ib_list = find(is_bsteel);

% 省略時は全変数を再計算対象とする
if nargin < 5
  recalculate_variable = true(1, obj.idMapper_.nxvar);
end

for k = 1:length(ib_list)
  isec = ib_list(k);
  varids = idsec2var(isec, :);
  varids = varids(varids > 0);
  varids = varids(recalculate_variable(varids));
  for j = 1:length(varids)
    xvar(varids(j)) = secdim(isec, j);
  end
end

return
end
