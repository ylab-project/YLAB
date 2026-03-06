function sectionCostConstant = getSectionCostConstant( ...
  obj, idsec2slist)
%getSectionCostConstant 断面コスト定数を取得
%   sectionCostConstant = getSectionCostConstant( ...
%     obj, idsec2slist)
%   は、断面リストIDと断面IDのペアから、各断面の
%   コスト定数を取得します。
%
%   入力引数:
%     idsec2slist - 断面リストID/断面IDペア配列 [n × 2]
%                   第1列: 断面リストID
%                   第2列: 断面ID
%
%   出力引数:
%     sectionCostConstant - 各断面のコスト定数 [n × 1]
%
%   例:
%     cc = calc.getSectionCostConstant(idsec2slist);
%
%   参考:
%     getSectionCostFactor

% 初期化（sectionCostConstant_から取得）
sectionCostConstant = obj.sectionCostConstant_;
for ilist=1:obj.nlist
  isTarget = idsec2slist(:,1)==ilist;
  sectionCostConstant(isTarget) = ...
    obj.secList_.cost_constant{ilist}( ...
      idsec2slist(isTarget,2));
end

return
end