function idreprcrs2rcrs = deprecated_idreprcrs2rcrs(secmgr)
%deprecated_idreprcrs2rcrs 代表RCRS断面からRCRS断面IDへの変換（非推奨）
%   idreprcrs2rcrs = deprecated_idreprcrs2rcrs(secmgr) は、
%   代表RCRS断面IDから対応するRCRS断面IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idreprcrs2rcrs - 代表RCRS断面のRCRS断面ID配列
%
%   参考:
%     IdMapper.getRepresentativeRcrsToRcrs

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idreprcrs2rcrsは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
[~, idreprcrs2rcrs] = ...
  unique(secmgr.idsec2srep(secmgr.idsec2stype==PRM.RCRS));

return
end