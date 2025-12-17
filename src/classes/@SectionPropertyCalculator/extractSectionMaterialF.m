function F = extractSectionMaterialF(obj, secdim, matF)
%extractSectionMaterialF 断面の材料F値を抽出
%   F = extractSectionMaterialF(obj, secdim, matF) は、
%   断面寸法データと材料F値配列を使用して、各断面に対応する
%   F値（許容応力度）を抽出します。
%
%   入力引数:
%     secdim - 断面寸法データ配列 [nsec × 7]
%              第6列: 断面リストID (idslist)
%              第7列: 断面ID (idsection)
%     matF - 材料F値配列 [nmat × 1]
%
%   出力引数:
%     F - 各断面のF値配列 [nsec × 1]
%
%   例:
%     secdim = [100, 100, 6, 9, 0, 1, 3; 200, 200, 8, 12, 0, 1, 5];
%     matF = [235; 325; 400];
%     F = calc.extractSectionMaterialF(secdim, matF);
%
%   参考:
%     extractMemberMaterialF, getIdSectionToMaterial
%        235
%        235

% 入力チェック
if size(secdim, 2) < 7
  error('secdimは7列以上である必要があります');
end

% 断面数
nsec = size(secdim, 1);

% 空の配列の場合は空の結果を返す
if nsec == 0
  F = zeros(0, 1);
  return
end

% secdimからidsec2slistを抽出（第6,7列）
idsec2slist = secdim(:, 6:7);

% 材料IDの取得
% 注: extractSectionMaterialIdは全断面を前提とするが、
% ここではsecdimの部分的な断面に対して適用
idsec2mat = obj.extractSectionMaterialId(idsec2slist);

% F値の抽出
F = zeros(nsec, 1);
valid_idx = idsec2mat > 0;
F(valid_idx) = matF(idsec2mat(valid_idx));

return
end