function sectionCostFactor = getSectionCostFactor(obj, idsec2slist)
%getSectionCostFactor - 断面コスト係数を取得
%
%   sectionCostFactor = getSectionCostFactor(obj, idsec2slist)
%   は、断面リストIDと断面IDのペアから、各断面のコスト係数を
%   取得します。
%
%   入力引数:
%     idsec2slist - 断面リストID/断面IDペア配列 [n × 2]
%                   第1列: 断面リストID
%                   第2列: 断面ID
%
%   出力引数:
%     sectionCostFactor - 各断面のコスト係数 [n × 1]
%
%   例:
%     cost = calc.getSectionCostFactor(idsec2slist);
%
%   参考:
%     getMemberCostFactor, getSectionStressFactor

sectionCostFactor = obj.sectionCostFactor_;
for ilist = 1:obj.nlist
  isTarget = idsec2slist(:,1) == ilist;
  idsec = idsec2slist(isTarget, 2);
  sectionCostFactor(isTarget) = obj.secList_.cost_factor{ilist}(idsec);
end

return
end
