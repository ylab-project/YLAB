function idrepbrbs2sec = deprecated_idrepbrbs2sec(secmgr)
%deprecated_idrepbrbs2sec 代表BRB断面から断面IDへの変換（非推奨）
%   idrepbrbs2sec = deprecated_idrepbrbs2sec(secmgr) は、
%   代表BRB断面IDから対応する断面IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrepbrbs2sec - 代表BRB断面の断面ID配列
%
%   参考:
%     IdMapper.mapRepresentativeBrbsToSection

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrepbrbs2secは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idrepbrbs2sec = secmgr.idsrep2sec(...
  secmgr.idsec2stype(secmgr.idsrep2sec)==PRM.BRB);

return
end