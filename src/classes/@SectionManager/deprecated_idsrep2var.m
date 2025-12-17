function idsrep2var = deprecated_idsrep2var(secmgr)
%deprecated_idsrep2var 代表断面から設計変数への変換（非推奨）
%   idsrep2var = deprecated_idsrep2var(secmgr) は、
%   代表断面IDから対応する設計変数IDを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idsrep2var - 代表断面の設計変数ID配列
%
%   参考:
%     IdMapper.getRepresentativeToVariable

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idsrep2varは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idsrep2var = secmgr.idsec2var(secmgr.idsrep2sec,:);

return
end