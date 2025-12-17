function memberCostFactor = getMemberCostFactor(obj, idsec2slist, ...
                                                 options)
%getMemberCostFactor 部材コスト係数を取得
%   memberCostFactor = getMemberCostFactor(obj, idsec2slist, options)
%   は、断面コスト係数を取得し、部材-断面マッピングを使用して
%   部材レベルのコスト係数に変換します。
%
%   入力引数:
%     idsec2slist - 断面リストID/断面IDペア配列 [n × 2]
%                   第1列: 断面リストID
%                   第2列: 断面ID
%     options - オプション構造体（getSectionCostFactorに渡される）
%
%   出力引数:
%     memberCostFactor - 各部材のコスト係数 [nmember × 1]
%
%   例:
%     cost = calc.getMemberCostFactor(idsec2slist, options);
%
%   参考:
%     getSectionCostFactor, getSectionStressFactor

secCostFactor = obj.getSectionCostFactor(idsec2slist, options);
idm2s = obj.idme2sec;
memberCostFactor = secCostFactor(idm2s);

return
end