function idslist = getIdSlistofVar(obj, idvar)
%getIdSlistofVar 変数が使用される断面リストIDを取得
%   idslist = getIdSlistofVar(obj, idvar) は、
%   指定された変数IDが使用される断面リストのIDを返します。
%
%   入力引数:
%     idvar - 変数ID (スカラー整数)
%
%   出力引数:
%     idslist - 断面リストID配列 [1×n]
%               該当する断面リストがない場合は空配列
%
%   例:
%     mapper = IdMapper(...);
%     ids = mapper.getIdSlistofVar(5);
%
%   参考:
%     SectionManager.getIdSlistofVar

% 変数を使用する断面を特定
istarget = any(obj.idsec2var == idvar, 2);

if any(istarget)
  % 該当断面の断面リストIDを取得
  idslist = unique(obj.idSectionList(istarget))';
else
  idslist = [];
end

return
end