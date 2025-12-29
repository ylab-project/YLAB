function idrepbrbs2var = deprecated_idrepbrbs2var(secmgr)
%deprecated_idrepbrbs2var 代表BRB断面から設計変数への変換（非推奨）
%   idrepbrbs2var = deprecated_idrepbrbs2var(secmgr) は、
%   代表BRB断面IDから対応する設計変数IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrepbrbs2var - 代表BRB断面の設計変数ID配列
%
%   参考:
%     IdMapper.mapRepresentativeBrbsToVariable

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrepbrbs2varは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idrepbrbs2var = secmgr.idsec2var(secmgr.idsrep2sec,:);
idrepbrbs2var = idrepbrbs2var(secmgr.idsrep2stype==PRM.BRB,:);

return
end