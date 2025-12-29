function idrepwfs2wfs = deprecated_idrepwfs2wfs(secmgr)
%deprecated_idrepwfs2wfs 代表WFS断面からWFS断面IDへの変換（非推奨）
%   idrepwfs2wfs = deprecated_idrepwfs2wfs(secmgr) は、
%   代表WFS断面IDから対応するWFS断面IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrepwfs2wfs - 代表WFS断面のWFS断面ID配列
%
%   参考:
%     IdMapper.getRepresentativeWfsToWfs

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrepwfs2wfsは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
[~, idrepwfs2wfs] = ...
  unique(secmgr.idsec2srep(secmgr.idsec2stype==PRM.WFS));

return
end