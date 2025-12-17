function isSN = extractSectionListIsSN(obj, idslist)
%extractSectionListIsSN 断面リスト全体のSN材フラグ配列を取得
%   isSN = extractSectionListIsSN(obj, idslist) は、
%   指定された断面リストID内の全断面のSN材フラグ配列を返します。
%
%   入力引数:
%     idslist - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     isSN - SN材フラグ配列 [1×nsecOfList] 論理値配列
%            nsecOfList: 断面リスト内の断面数
%            true: SN材、false: 非SN材
%
%   例:
%     isSN = calc.extractSectionListIsSN(3);
%     % 断面リスト3内の全断面のSN材フラグ配列を取得
%
%   参考:
%     extractSectionListMaterialId, extractSectionListMaterialF

% 入力チェック
if isempty(obj.secList_)
  error('SectionPropertyCalculator:NotInitialized', ...
    'secListが初期化されていません');
end

% SN材フラグ配列を取得
isSN = obj.secList_.isSN{idslist};

return
end