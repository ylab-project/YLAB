function idrephss2var = mapRepresentativeHssToVariable(obj)
%mapRepresentativeHssToVariable 代表HSS断面から設計変数への変換
%   idrephss2var = mapRepresentativeHssToVariable(obj) は、
%   代表HSS断面IDから対応する設計変数IDへのマッピングを返します。
%
%   出力引数:
%     idrephss2var - 代表HSS断面→設計変数 [nrephss×ndim]
%
%   参考:
%     mapRepresentativeHssToSection, mapRepresentativeToHss

if isempty(obj.idsec2var_)
  error('IdMapper:NoSectionToVariable', ...
    'idsec2varが設定されていません。7引数コンストラクタを使用してください');
end

idsrep2var = obj.idsrep2var;
idsrep2stype = obj.idsrep2stype;
idrephss2var = idsrep2var(idsrep2stype == PRM.HSS, :);

return
end