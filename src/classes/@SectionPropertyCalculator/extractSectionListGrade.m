function grade = extractSectionListGrade(obj, idslist)
%extractSectionListGrade 断面リスト全体の鋼種配列を取得
%   grade = extractSectionListGrade(obj, idslist) は、
%   指定された断面リストID内の全断面の鋼種配列を返します。
%
%   入力引数:
%     idslist - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     grade - 鋼種配列 [1×nsecOfList]
%             PRM.GRADE_SS/SN/SM の整数値
%
%   参考:
%     extractSectionListMaterialF, extractSectionListIsSN

% 入力チェック
if isempty(obj.secList_) || isempty(obj.material)
  error('SectionPropertyCalculator:NotInitialized', ...
    'secListまたはmaterialが初期化されていません');
end

% 材料ID配列を取得
idmat = obj.extractSectionListMaterialId(idslist);

% 鋼種配列に変換
grade = obj.material.steel_grade(idmat);

return
end
