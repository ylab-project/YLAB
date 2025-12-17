function idrephss2hss = deprecated_idrephss2hss(secmgr)
%deprecated_idrephss2hss 代表HSS断面からHSS断面IDへの変換（非推奨）
%   idrephss2hss = deprecated_idrephss2hss(secmgr) は、
%   代表HSS断面IDから対応するHSS断面IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idrephss2hss - 代表HSS断面のHSS断面ID配列
%
%   参考:
%     IdMapper.getRepresentativeHssToHss

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idrephss2hssは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
[~, idrephss2hss] = ...
  unique(secmgr.idsec2srep(secmgr.idsec2stype==PRM.HSS));

return
end