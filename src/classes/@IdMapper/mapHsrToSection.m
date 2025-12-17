function idhsr2sec = mapHsrToSection(obj)
%mapHsrToSection HSR断面→断面インデックスマッピングを取得
%   idhsr2sec = mapHsrToSection(obj) は、HSR断面から全体断面
%   インデックスへのマッピングを返します。
%
%   出力引数:
%     idhsr2sec - HSR断面→断面マッピング [nhsr×1]
%
%   例:
%     idhsr2sec = mapper.mapHsrToSection();

% HSR断面のインデックスを取得
isHsr = (obj.idsec2stype_ == PRM.HSR);
idhsr2sec = find(isHsr);

return
end