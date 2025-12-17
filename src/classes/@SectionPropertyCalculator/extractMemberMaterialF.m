function F = extractMemberMaterialF(obj, secdim, matF)
%extractMemberMaterialF 部材の材料F値を抽出
%   F = extractMemberMaterialF(obj, secdim, matF) は、
%   断面寸法データと材料F値配列を使用して、各部材に対応する
%   F値（許容応力度）を抽出します。
%
%   入力引数:
%     secdim - 断面寸法データ配列 [nsec × 7]
%              第6列: 断面リストID (idslist)
%              第7列: 断面ID (idsection)
%     matF - 材料F値配列 [nmat × 1]
%
%   出力引数:
%     F - 各部材のF値配列 [nmember × 1]
%
%   例:
%     secdim = [100, 100, 6, 9, 0, 1, 3; 200, 200, 8, 12, 0, 1, 5];
%     matF = [235; 325; 400];
%     F = calc.extractMemberMaterialF(secdim, matF);
%
%   参考:
%     extractSectionMaterialF, getIdMemberToMaterial
%        235
%        235
%        325
%
% See also
%   extractSectionMaterialF, getIdMemberToMaterial

% 入力チェック
if size(secdim, 2) < 7
  error('secdimは7列以上である必要があります');
end

% secdimからidsec2slistを抽出（第6,7列）
idsec2slist = secdim(:, 6:7);

% 材料IDの取得
idme2mat = obj.extractMemberMaterialId(idsec2slist);

% F値の抽出
nme = length(idme2mat);
F = zeros(nme, 1);
valid_idx = idme2mat > 0;
if any(valid_idx)
  F(valid_idx) = matF(idme2mat(valid_idx));
end

return
end