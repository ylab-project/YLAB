function idsrep2stype = deprecated_idsrep2stype(secmgr)
%deprecated_idsrep2stype 代表断面から断面タイプへの変換（非推奨）
%   idsrep2stype = deprecated_idsrep2stype(secmgr) は、
%   代表断面IDから対応する断面タイプを取得します。
%
%   この関数は非推奨です。今後はIdMapperの該当メソッドを
%   使用してください。
%
%   入力引数:
%     なし（SectionManagerのDependentプロパティ）
%
%   出力引数:
%     idsrep2stype - 代表断面の断面タイプ配列
%
%   参考:
%     IdMapper.getRepresentativeToSectionType

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_idsrep2stypeは非推奨です。' ...
  '今後はIdMapperの該当メソッドを使用してください。']);

% 旧実装
idsrep2stype = secmgr.idsec2stype(secmgr.idsrep2sec,:);

return
end