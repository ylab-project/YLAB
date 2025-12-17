function ub = getGlobalUpperBounds(obj)
%getGlobalUpperBounds 全断面リストの上限値を統合取得
%   ub = getGlobalUpperBounds(obj) は、全ての断面リストから
%   各変数の上限値を取得し、最大値を返します。最適化アルゴリズムが
%   必要とする全体制約の上限値を提供します。
%
%   出力引数:
%     ub - 統合上限値ベクトル [nxvar×1]
%          各変数の全リストにおける最大上限値
%
%   例:
%     ub = validator.getGlobalUpperBounds();
%
%   参考:
%     getGlobalLowerBounds, getUpperBounds

% 全断面リストの上限値を収集
nxvar_ = obj.nxvar;
nlist_ = obj.nlist;
ub = nan(nxvar_, nlist_);

for id = 1:nlist_
  ub(:, id) = obj.getUpperBounds(id);
end

% 各変数の最大値を取得（NaNを無視）
ub = max(ub, [], 2);

return
end