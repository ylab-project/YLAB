function idrephsr2var = mapRepresentativeHsrToVariable(obj)
%mapRepresentativeHsrToVariable 代表HSR断面→変数マッピングを取得
%   idrephsr2var = mapRepresentativeHsrToVariable(obj) は、
%   代表HSR断面から変数へのマッピングを返します。
%
%   出力引数:
%     idrephsr2var - 代表HSR断面→変数マッピング [nrephsr×2]
%                    列1: D変数ID、列2: t変数ID
%
%   例:
%     idrephsr2var = mapper.mapRepresentativeHsrToVariable();

if isempty(obj.idsec2var_)
  error('IdMapper:NoSectionToVariable', ...
    'idsec2varが設定されていません。7引数コンストラクタを使用してください');
end

% HSRの代表断面を取得
idsrep2var = obj.idsrep2var;
idsrep2stype = obj.idsrep2stype;

% HSR代表断面のみを抽出
idrephsr2var = idsrep2var(idsrep2stype == PRM.HSR, :);

% HSRは2列（D, t）のみ必要
if size(idrephsr2var, 2) > 2
  idrephsr2var = idrephsr2var(:, 1:2);
end

return
end