function idbrbs2repbrbs = mapBrbsToRepresentative(obj)
%mapBrbsToRepresentative 全BRB断面から代表BRB断面への変換
%   idbrbs2repbrbs = mapBrbsToRepresentative(obj) は、
%   全BRB断面から対応する代表BRB断面へのマッピング配列を返します。
%
%   出力引数:
%     idbrbs2repbrbs - BRB断面→代表BRB断面 [nbrbs×1]
%
%   参考:
%     mapRepresentativeToBrbs, mapWfsToRepresentative, mapHssToRepresentative

if obj.nbrbs == 0
  idbrbs2repbrbs = [];
  return;
end

% BRB断面のみを抽出してuniqueで代表断面への変換
[~, ~, idbrbs2repbrbs] = ...
  unique(obj.idsec2srep_(obj.idsec2shape_ == PRM.BRB));

return
end