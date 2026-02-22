function record = getListRecord(obj, secdim)
%getListRecord 断面テーブルレコードを取得
%   record = getListRecord(obj, secdim) は、
%   secdim の末尾2列（断面リストID, 断面ID）から
%   対応するテーブルレコードを取得します。
%
%   入力引数:
%     secdim - 断面寸法配列 [n×ncol]
%              末尾2列: 断面リストID, 断面ID
%
%   出力引数:
%     record - テーブルレコード (table型) [n×列数]
%              各断面リストの全列データを含む
%
%   例:
%     tbTable = accessor.getListRecord( ...
%       secdim(stype==PRM.TB, :));
%
%   参考:
%     SectionListHandler.list

% 引数の検証
if nargin < 2
  error('SectionStandardAccessor:InsufficientArguments', ...
    '断面寸法配列が必要です');
end

% 空配列の処理
if isempty(secdim)
  record = [];
  return
end

% 末尾2列を断面IDペアとして取得
sectionIds = secdim(:, end-1:end);

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