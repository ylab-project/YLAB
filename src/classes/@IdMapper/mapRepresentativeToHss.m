function idrephss2hss = mapRepresentativeToHss(obj)
%mapRepresentativeToHss 代表HSS断面からHSS断面への変換
%   idrephss2hss = mapRepresentativeToHss(obj) は、
%   代表HSS断面IDから対応するHSS断面IDへのマッピング配列を返します。
%   各代表HSS断面に対して最初のHSS断面IDを返します。
%
%   出力引数:
%     idrephss2hss - 代表HSS断面→HSS断面 [nrephss×1]
%
%   参考:
%     mapHssToRepresentative, mapRepresentativeToWfs, mapRepresentativeToBrbs

% HSS断面の代表断面を取得
[~, idrephss2hss] = unique(obj.idsec2srep_(obj.idsec2stype_ == PRM.HSS));

return
end