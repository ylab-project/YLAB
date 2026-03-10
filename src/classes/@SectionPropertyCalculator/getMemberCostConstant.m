function memberCostConstant = getMemberCostConstant(obj, idsec2slist)
%getMemberCostConstant - 部材コスト定数を取得
%
%   memberCostConstant = getMemberCostConstant( ...
%     obj, idsec2slist) は、
%   断面コスト定数を取得し、部材-断面マッピングを使用して
%   部材レベルのコスト定数に変換します。
%
%   入力引数:
%     idsec2slist - 断面リストID/断面IDペア配列 [n × 2]
%                   第1列: 断面リストID
%                   第2列: 断面ID
%
%   出力引数:
%     memberCostConstant - 各部材のコスト定数 [nmember × 1]
%
%   例:
%     cc = calc.getMemberCostConstant(idsec2slist);
%
%   参考:
%     getSectionCostConstant, getMemberCostFactor

secCostConstant = obj.getSectionCostConstant(idsec2slist);
idm2s = obj.idme2sec;
memberCostConstant = secCostConstant(idm2s);

return
end
