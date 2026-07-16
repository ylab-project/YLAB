function idhsr2rephsr = mapHsrToRepresentative(obj)
%mapHsrToRepresentative HSR断面→代表HSR断面マッピングを取得
%   idhsr2rephsr = mapHsrToRepresentative(obj) は、HSR断面から
%   代表HSR断面へのマッピングを返します。
%   HSRは全断面が代表断面のため、1:nhsrの連番を返します。
%
%   出力引数:
%     idhsr2rephsr - HSR断面→代表HSR断面マッピング [nhsr×1]
%
%   例:
%     idhsr2rephsr = mapper.mapHsrToRepresentative();

idhsr2rephsr = obj.idhsr2rephsr_;

return
end