function sectionCostFactor = getSectionCostFactor(obj, idsec2slist, ...
                                                  options)
%getSectionCostFactor 断面コスト係数を取得
%   sectionCostFactor = getSectionCostFactor(obj, idsec2slist, ...
%     options) は、断面リストIDと断面IDのペアから、各断面の
%   コスト係数を取得します。オプションで漸進的コスト変化を適用できます。
%
%   入力引数:
%     idsec2slist - 断面リストID/断面IDペア配列 [n × 2]
%                   第1列: 断面リストID
%                   第2列: 断面ID
%     options - オプション構造体
%       .do_progressive_cost_change - 漸進的コスト変化の有効化フラグ
%       .iter - 現在のイテレーション数
%       .progressive_cost_change_iter - 漸進的変化の終了イテレーション
%
%   出力引数:
%     sectionCostFactor - 各断面のコスト係数 [n × 1]
%
%   例:
%     cost = calc.getSectionCostFactor(idsec2slist, options);
%
%   参考:
%     getMemberCostFactor, getSectionStressFactor

do_progressive_cost_change = options.do_progressive_cost_change;
iter = options.iter;
iter_end = options.progressive_cost_change_iter;
% 初期化（sectionCostFactor_から取得）
sectionCostFactor = obj.sectionCostFactor_;
for ilist=1:obj.nlist
  isTarget = idsec2slist(:,1)==ilist;
  idsec = idsec2slist(isTarget,2);
  costfactor_ = obj.secList_.cost_factor{ilist};

  % コスト差を漸増的につける場合
  if do_progressive_cost_change && iter>0
    c0 = min(costfactor_);
    dc = costfactor_-c0;
    dfac = (iter-2)/(iter_end-2);
    dfac(dfac>1) = 1;
    costfactor_ = c0+dfac*dc(:);
  end
  
  sectionCostFactor(isTarget) = costfactor_(idsec);
end

return
end