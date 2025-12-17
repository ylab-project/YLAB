function idrepwfs2sec = deprecated_idrepwfs2sec(secmgr)
%deprecated_idrepwfs2sec 代表WFS断面から断面IDへの変換（非推奨）
%   idrepwfs2sec = deprecated_idrepwfs2sec(secmgr) は、
%   代表WFS断面IDから対応する断面IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrepwfs2sec - 代表WFS断面の断面ID配列
%
%   参考:
%     IdMapper.mapRepresentativeWfsToSection

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrepwfs2secは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idrepwfs2sec = secmgr.idsrep2sec(...
  secmgr.idsec2stype(secmgr.idsrep2sec)==PRM.WFS);

return
end