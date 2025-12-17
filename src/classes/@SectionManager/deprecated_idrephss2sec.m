function idrephss2sec = deprecated_idrephss2sec(secmgr)
%deprecated_idrephss2sec 代表HSS断面から断面IDへの変換（非推奨）
%   idrephss2sec = deprecated_idrephss2sec(secmgr) は、
%   代表HSS断面IDから対応する断面IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrephss2sec - 代表HSS断面の断面ID配列
%
%   参考:
%     IdMapper.mapRepresentativeHssToSection

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrephss2secは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idrephss2sec = secmgr.idsrep2sec(...
  secmgr.idsec2stype(secmgr.idsrep2sec)==PRM.HSS);

return
end