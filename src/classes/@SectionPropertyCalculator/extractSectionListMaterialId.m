function idmat = extractSectionListMaterialId(obj, idslist)
%extractSectionListMaterialId 断面リスト全体の材料ID配列を取得
%   idmat = extractSectionListMaterialId(obj, idslist) は、
%   指定された断面リストID内の全断面の材料ID配列を返します。
%
%   入力引数:
%     idslist - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     idmat - 材料ID配列 [nsecOfList×1]
%             nsecOfList: 断面リスト内の断面数
%
%   例:
%     idmat = calc.extractSectionListMaterialId(3);
%     % 断面リスト3内の全断面の材料ID配列を取得
%
%   参考:
%     extractSectionMaterialId, extractSectionListMaterialF

% 入力チェック
if isempty(obj.secList_)
  error('SectionPropertyCalculator:NotInitialized', ...
    'secListが初期化されていません');
end

% 候補断面ごとに、属するサブリストの材料IDを引く
idmat = obj.secList_.idmaterial(obj.secList_.idsublist{idslist});

return
end
