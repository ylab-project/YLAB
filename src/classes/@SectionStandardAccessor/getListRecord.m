function record = getListRecord(obj, sectionIds)
%getListRecord 断面テーブルレコードを取得
%   record = getListRecord(obj, sectionIds) は、
%   指定された断面IDペアに対応するテーブルレコードを取得します。
%
%   入力引数:
%     sectionIds - 断面IDペア配列 [n×2]
%                  第1列: 断面リストID
%                  第2列: 断面ID
%
%   出力引数:
%     record - テーブルレコード (table型) [n×列数]
%              各断面リストの全列データを含む
%
%   例:
%     % 断面リスト1の断面5,8のレコード取得
%     data = accessor.getListRecord([1, 5; 1, 8]);
%     % BRB断面での使用例
%     brbIds = secdim(stype==PRM.BRB, end-1:end);
%     brbTable = accessor.getListRecord(brbIds);
%     area = brbTable.A;
%
%   参考:
%     SectionListHandler.list

% 引数の検証
if nargin < 2
  error('SectionStandardAccessor:InsufficientArguments', ...
    '断面IDペア配列が必要です');
end

% 空配列の処理
if isempty(sectionIds)
  record = [];
  return
end

% 入力形式の検証
if size(sectionIds, 2) ~= 2
  error('SectionStandardAccessor:InvalidFormat', ...
    '断面IDペア配列は [n×2] の形式である必要があります');
end

% 計算の準備
uniqueListIds = unique(sectionIds(:, 1));
nRows = size(sectionIds, 1);

% パフォーマンス最適化: 単一断面リストの場合の高速化
if length(uniqueListIds) == 1
  % 単一断面リスト（95%のケース）: 直接アクセスで大幅高速化
  listId = uniqueListIds(1);
  record = obj.secList_.list{listId}(sectionIds(:, 2), :);
else
  % 複数断面リスト（5%のケース）: 従来のループ処理
  firstListId = uniqueListIds(1);
  firstTable = obj.secList_.list{firstListId};
  record = firstTable(ones(1, nRows), :);
  
  % 各断面リストから該当レコードを抽出
  for i = 1:length(uniqueListIds)
    listId = uniqueListIds(i);
    isTargetList = sectionIds(:, 1) == listId;
    targetSectionIds = sectionIds(isTargetList, 2);
    
    record(isTargetList, :) = obj.secList_.list{listId}(targetSectionIds, :);
  end
end

return
end