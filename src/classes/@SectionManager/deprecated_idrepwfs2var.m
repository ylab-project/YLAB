function idrepwfs2var = deprecated_idrepwfs2var(secmgr)
%deprecated_idrepwfs2var 代表WFS断面から設計変数への変換（非推奨）
%   idrepwfs2var = deprecated_idrepwfs2var(secmgr) は、
%   代表WFS断面IDから対応する設計変数IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrepwfs2var - 代表WFS断面の設計変数ID配列
%
%   参考:
%     IdMapper.mapRepresentativeWfsToVariable

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrepwfs2varは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idrepwfs2var = secmgr.idsec2var(secmgr.idsrep2sec,:);
idrepwfs2var = idrepwfs2var(secmgr.idsrep2stype==PRM.WFS,:);

return
end