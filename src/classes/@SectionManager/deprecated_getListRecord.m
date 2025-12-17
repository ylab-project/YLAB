function ret = deprecated_getListRecord(secmgr, id)
%deprecated_getListRecord 断面テーブルレコードを取得（非推奨）
%   ret = deprecated_getListRecord(secmgr, id) は、
%   指定された断面IDペアに対応するテーブルレコードを取得します。
%
%   非推奨: このメソッドは非推奨です。
%   代わりにstandardAccessor.getListRecord()を使用してください。
%
%   入力引数:
%     id - 断面IDペア配列 [n×2]
%          第1列: 断面リストID, 第2列: 断面ID
%
%   出力引数:
%     ret - テーブルレコード (table型)
%
%   参考:
%     SectionStandardAccessor.getListRecord

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  'deprecated_getListRecord は非推奨です。standardAccessor.getListRecord() を使用してください。');

% 元の実装を保持（新旧比較テストのため）
idslist = unique(id(:,1));

% テーブルの初期化
n = size(id,1);
if n==0
  ret = [];
  return
end
ret = secmgr.secList.list{idslist(1)}(ones(1,n),:);

% 該当行の抽出
for i=1:length(idslist)
  ids = idslist(i);
  istarget = id(:,1)==idslist(i);
  iddd = id(istarget,2);
  ret(istarget,:) = secmgr.secList.list{ids}(iddd,:);
end

return
end