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

% BRB断面のインデックスを取得
isbrbs = (obj.idsec2stype_ == PRM.BRB);
idsec_brbs = find(isbrbs);

if isempty(idsec_brbs)
  idbrbs2repbrbs = [];
  return;
end

% BRB断面の代表断面値を取得
srep_brbs = obj.idsec2srep_(isbrbs);

% unique関数で代表断面への変換
[~, ~, idbrbs2repbrbs] = unique(srep_brbs);

return
end