function memberCostConstant = getMemberCostConstant(obj, idsec2slist, ...
  member)
%getMemberCostConstant - 部材コスト定数を取得
%
%   memberCostConstant = getMemberCostConstant( ...
%     obj, idsec2slist, member) は、
%   断面コスト定数を取得し、部材-断面マッピングを使用して
%   部材レベルのコスト定数に変換します。
%
%   入力引数:
%     obj - 断面特性と材料を参照する計算オブジェクト
%     idsec2slist - 断面リストID/断面IDペア配列 [nsec×2]
%                   第1列: 断面リストID
%                   第2列: 断面ID
%     member - 現在の解析部材。property.idsecは各部材の断面番号
%
%   出力引数:
%     memberCostConstant - 各部材のコスト定数 [nme×1]
%
%   例:
%     cc = calc.getMemberCostConstant(idsec2slist, member);
%
%   参考:
%     getSectionCostConstant, getMemberCostFactor

secCostConstant = obj.getSectionCostConstant(idsec2slist);
idm2s = member.property.idsec;
memberCostConstant = secCostConstant(idm2s);

return
end
