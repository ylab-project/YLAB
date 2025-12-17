function nx = deprecated_get_nxvar(secmgr)
%deprecated_get_nxvar [非推奨] 変数の総数を取得
%   nx = deprecated_get_nxvar(secmgr) は、
%   8つの変数ID配列の最大値から変数の総数を計算します。
%
%   警告: このメソッドは非推奨です。
%   新しいコードではget.nxvarプロパティ（IdMapper.nxvar参照）を
%   使用してください。
%
%   出力引数:
%     nx - 変数の総数 (スカラー整数)
%
%   参考:
%     IdMapper.nxvar

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  'deprecated_get_nxvarは非推奨です。get.nxvarを使用してください。');

% 既存の実装（変更なし）
nx = max([...
  secmgr.idH2var; secmgr.idB2var; ...
  secmgr.idtw2var; secmgr.idtf2var; ...
  secmgr.idD2var; secmgr.idt2var; ...
  secmgr.idBrb1_var; secmgr.idBrb2_var]);

return
end