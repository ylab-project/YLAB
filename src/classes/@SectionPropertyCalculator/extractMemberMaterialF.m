function F = extractMemberMaterialF(obj, secdim, matF, member)
%extractMemberMaterialF - 各部材の材料F値を抽出する
%
%   F = extractMemberMaterialF(obj, secdim, matF, member) は、
%   断面の材料番号を部材へ対応させ、F値（基準強度）を返す。
%
%   入力引数:
%     obj    - 断面性能計算オブジェクト
%     secdim - 全断面の寸法 [nsec×7]、第6・7列はリストと断面の番号
%     matF   - 材料のF値 [nmat×1] (N/mm²)
%     member - 現在の解析部材。property.idsecは各部材の断面番号
%
%   出力引数:
%     F - 各部材のF値 [nme×1] (N/mm²)、未割当は0
%
%   例:
%     F = calc.extractMemberMaterialF(secdim, matF, member);
%
%   参考:
%     extractSectionMaterialF, extractMemberMaterialId
% 入力チェック
if size(secdim, 2) < 7
  error('secdimは7列以上である必要があります');
end

% secdimからidsec2slistを抽出（第6,7列）
idsec2slist = secdim(:, ...
  [PRM.MAPPED_SECDIM_SLIST PRM.MAPPED_SECDIM_SECTION]);

% 材料IDの取得
idme2mat = obj.extractMemberMaterialId(idsec2slist, member);

% F値の抽出
nme = length(idme2mat);
F = zeros(nme, 1);
valid_idx = idme2mat > 0;
if any(valid_idx)
  F(valid_idx) = matF(idme2mat(valid_idx));
end

return
end
