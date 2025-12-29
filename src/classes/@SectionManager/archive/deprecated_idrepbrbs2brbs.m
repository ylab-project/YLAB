function idrepbrbs2brbs = deprecated_idrepbrbs2brbs(secmgr)
%deprecated_idrepbrbs2brbs 代表BRB断面からBRB断面IDへの変換（非推奨）
%   idrepbrbs2brbs = deprecated_idrepbrbs2brbs(secmgr) は、
%   代表BRB断面IDから対応するBRB断面IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrepbrbs2brbs - 代表BRB断面のBRB断面ID配列
%
%   参考:
%     IdMapper.getRepresentativeBrbsToBrbs

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrepbrbs2brbsは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
[~, idrepbrbs2brbs] = ...
  unique(secmgr.idsec2srep(secmgr.idsec2stype==PRM.BRB));

return
end