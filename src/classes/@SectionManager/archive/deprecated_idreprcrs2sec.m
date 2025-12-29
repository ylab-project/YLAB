function idreprcrs2sec = deprecated_idreprcrs2sec(secmgr)
%deprecated_idreprcrs2sec 代表RCRS断面から断面IDへの変換（非推奨）
%   idreprcrs2sec = deprecated_idreprcrs2sec(secmgr) は、
%   代表RCRS断面IDから対応する断面IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idreprcrs2sec - 代表RCRS断面の断面ID配列
%
%   参考:
%     IdMapper.mapRepresentativeRcrsToSection

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idreprcrs2secは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idreprcrs2sec = secmgr.idsrep2sec(...
  secmgr.idsec2stype(secmgr.idsrep2sec)==PRM.RCRS);

return
end