function memberCostFactor = getMemberCostFactor(obj, idsec2slist, member)
%getMemberCostFactor - 部材コスト係数を取得
%
%   memberCostFactor = getMemberCostFactor(obj, idsec2slist, member)
%   は、断面コスト係数を取得し、部材-断面マッピングを使用して
%   部材レベルのコスト係数に変換します。
%
%   入力引数:
%     obj - 断面特性と材料を参照する計算オブジェクト
%     idsec2slist - 断面リストID/断面IDペア配列 [nsec×2]
%                   第1列: 断面リストID
%                   第2列: 断面ID
%     member - 現在の解析部材。property.idsecは各部材の断面番号
%
%   出力引数:
%     memberCostFactor - 各部材のコスト係数 [nme×1]
%
%   例:
%     cost = calc.getMemberCostFactor(idsec2slist, member);
%
%   参考:
%     getSectionCostFactor, getSectionStressFactor

secCostFactor = obj.getSectionCostFactor(idsec2slist);
idm2s = member.property.idsec;
memberCostFactor = secCostFactor(idm2s);

return
end
