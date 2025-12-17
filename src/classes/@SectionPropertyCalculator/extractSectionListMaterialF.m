function F = extractSectionListMaterialF(obj, idslist)
%extractSectionListMaterialF 断面リスト全体のF値配列を取得
%   F = extractSectionListMaterialF(obj, idslist) は、
%   指定された断面リストID内の全断面のF値配列を返します。
%
%   入力引数:
%     idslist - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     F - F値配列 [1×nsecOfList] [MPa]
%         nsecOfList: 断面リスト内の断面数
%
%   例:
%     F = calc.extractSectionListMaterialF(3);
%     % 断面リスト3内の全断面のF値配列を取得
%
%   参考:
%     extractSectionListMaterialId, extractSectionMaterialF

% 入力チェック
if isempty(obj.secList_) || isempty(obj.material)
  error('SectionPropertyCalculator:NotInitialized', ...
    'secListまたはmaterialが初期化されていません');
end

% 材料ID配列を取得
idmat = obj.extractSectionListMaterialId(idslist);

% F値配列に変換
F = obj.material.F(idmat);

return
end