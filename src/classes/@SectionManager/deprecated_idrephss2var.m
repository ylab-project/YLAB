function idrephss2var = deprecated_idrephss2var(secmgr)
%deprecated_idrephss2var 代表HSS断面から設計変数への変換（非推奨）
%   idrephss2var = deprecated_idrephss2var(secmgr) は、
%   代表HSS断面IDから対応する設計変数IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrephss2var - 代表HSS断面の設計変数ID配列
%
%   参考:
%     IdMapper.mapRepresentativeHssToVariable

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrephss2varは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idrephss2var = secmgr.idsec2var(secmgr.idsrep2sec,:);
idrephss2var = idrephss2var(secmgr.idsrep2stype==PRM.HSS,:);

return
end