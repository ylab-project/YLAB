function [F, idsec2mat] = extractSectionMaterialF(obj, secdim, matF)
%extractSectionMaterialF - 全断面の材料F値と材料番号を抽出する
%   [F, idsec2mat] = extractSectionMaterialF(obj, secdim, matF) は、
%   断面寸法データと材料F値配列を使用して、各断面に対応する
%   F値（基準強度）と材料番号を抽出する。
%
%   入力引数:
%     obj - 断面性能計算オブジェクト
%     secdim - 全断面の寸法データ配列 [nsec × 7]
%              第6列: 断面リストID (idslist)
%              第7列: 断面ID (idsection)
%     matF - 材料F値配列 [nmat × 1]
%
%   出力引数:
%     F         - 各断面のF値配列 [nsec × 1] (N/mm²)
%     idsec2mat - 各断面の材料番号 [nsec × 1]（未割当は0）
%
%   例:
%     secdim = [100, 100, 6, 9, 0, 1, 3; 200, 200, 8, 12, 0, 1, 5];
%     matF = [235; 325; 400];
%     [F, idsec2mat] = calc.extractSectionMaterialF(secdim, matF);
%
%   参考:
%     extractSectionMaterialId, extractMemberMaterialF

% 入力チェック
if size(secdim, 2) < 7
  error('secdimは7列以上である必要があります');
end

% 断面数
nsec = size(secdim, 1);

% 空の配列の場合は空の結果を返す
if nsec == 0
  F = zeros(0, 1);
  idsec2mat = zeros(0, 1);
  return
end

% secdimからidsec2slistを抽出（第6,7列）
idsec2slist = secdim(:, ...
  [PRM.MAPPED_SECDIM_SLIST PRM.MAPPED_SECDIM_SECTION]);

% 材料IDの取得
idsec2mat = obj.extractSectionMaterialId(idsec2slist);

% F値の抽出
F = zeros(nsec, 1);
valid_idx = idsec2mat > 0;
F(valid_idx) = matF(idsec2mat(valid_idx));

return
end