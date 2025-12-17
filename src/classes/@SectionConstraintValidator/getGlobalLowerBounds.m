function lb = getGlobalLowerBounds(obj)
%getGlobalLowerBounds 全断面リストの下限値を統合取得
%   lb = getGlobalLowerBounds(obj) は、全ての断面リストから
%   各変数の下限値を取得し、最小値を返します。最適化アルゴリズムが
%   必要とする全体制約の下限値を提供します。
%
%   出力引数:
%     lb - 統合下限値ベクトル [nxvar×1]
%          各変数の全リストにおける最小下限値
%
%   例:
%     lb = validator.getGlobalLowerBounds();
%
%   参考:
%     getGlobalUpperBounds, getLowerBounds

% 全断面リストの下限値を収集
nxvar_ = obj.nxvar;
nlist_ = obj.nlist;
lb = nan(nxvar_, nlist_);

for id = 1:nlist_
  lb(:, id) = obj.getLowerBounds(id);
end

% 各変数の最小値を取得（NaNを無視）
lb = min(lb, [], 2);

return
end