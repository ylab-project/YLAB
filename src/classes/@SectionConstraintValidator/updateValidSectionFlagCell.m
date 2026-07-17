function updateValidSectionFlagCell(obj, idPhase)
%updateValidSectionFlagCell 現在フェーズ用の有効フラグを更新
%   全フェーズの有効断面フラグ正本から、指定フェーズで候補検索に
%   使用する有効断面フラグを抽出して保存します。
%
%   入力引数:
%     idPhase - 現在フェーズID

obj.currentValidSectionFlagCell_ = cell(obj.nlist, 1);
for idsList = 1:obj.nlist
  obj.currentValidSectionFlagCell_{idsList} = ...
    obj.extractValidSectionFlags(idsList, idPhase);
end

return
end