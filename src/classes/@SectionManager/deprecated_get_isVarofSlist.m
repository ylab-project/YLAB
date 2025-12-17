function isVarofSlist = deprecated_get_isVarofSlist(secmgr)
%deprecated_get_isVarofSlist 変数-断面リストマッピング取得（非推奨）
%   isVarofSlist = deprecated_get_isVarofSlist(secmgr) は、
%   各変数がどの断面リストに属するかを示す論理配列を返します。
%
%   この関数は非推奨です。代わりにget.isVarofSlistプロパティ
%   （IdMapperに委譲）を使用してください。
%
%   出力引数:
%     isVarofSlist - 変数-断面リストマッピング [nxvar×nlist] 論理配列
%
%   参考:
%     get.isVarofSlist, IdMapper.getIsVarofSlist

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_get_isVarofSlist は非推奨です。' ...
   '代わりに isVarofSlist プロパティを使用してください。']);

% 旧実装（変更なし）
isVarofSlist = false(secmgr.nxvar, secmgr.nlist);
for il = 1:secmgr.nlist
  iddd = secmgr.idsec2var((secmgr.idSectionList == il), :);
  iddd = iddd(:);
  iddd(iddd == 0) = [];
  isVarofSlist(iddd, il) = true;
end

return
end