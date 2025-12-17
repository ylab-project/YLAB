function sectionStressFactor = getSectionStressFactor(obj, idsec2slist)
%getSectionStressFactor 断面応力係数を取得
%   sectionStressFactor = getSectionStressFactor(obj, idsec2slist)
%   は、断面リストIDと断面IDのペアから、各断面の応力係数を取得します。
%   断面リストごとに定義された設計応力係数を参照します。
%
%   入力引数:
%     idsec2slist - 断面リストID/断面IDペア配列 [n × 2]
%                   第1列: 断面リストID
%                   第2列: 断面ID
%
%   出力引数:
%     sectionStressFactor - 各断面の応力係数 [n × 1]
%
%   例:
%     stress = calc.getSectionStressFactor(idsec2slist);
%
%   参考:
%     getSectionCostFactor, extractSectionMaterialF

% 初期化（sectionStressFactor_から取得）
sectionStressFactor = obj.sectionStressFactor_;
for ilist=1:obj.nlist
  isTarget = idsec2slist(:,1)==ilist;
  sectionStressFactor(isTarget) = ...
    obj.secList_.design_stress_factor{ilist}(idsec2slist(isTarget,2));
end

return
end