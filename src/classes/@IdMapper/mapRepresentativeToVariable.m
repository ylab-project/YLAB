function idsrep2var = mapRepresentativeToVariable(obj)
%mapRepresentativeToVariable 代表断面から設計変数への変換
%   idsrep2var = mapRepresentativeToVariable(obj) は、
%   すべての代表断面IDから対応する設計変数IDへのマッピングを返します。
%
%   出力引数:
%     idsrep2var - 代表断面→設計変数 [nsrep×ndim]
%
%   参考:
%     mapRepresentativeToSection

if ~isempty(obj.idsec2var_)
  % 7引数コンストラクタで提供されている場合
  idsrep2sec = obj.mapRepresentativeToSection();
  idsrep2var = obj.idsec2var_(idsrep2sec,:);
else
  % idsec2varが提供されていない場合はエラー
  error('IdMapper:NoSectionToVariable', ...
    'idsec2varが設定されていません。7引数コンストラクタを使用してください');
end

return
end