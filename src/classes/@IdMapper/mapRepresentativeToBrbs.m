function idrepbrbs2brbs = mapRepresentativeToBrbs(obj)
%mapRepresentativeToBrbs 代表BRB断面からBRB断面への変換
%   idrepbrbs2brbs = mapRepresentativeToBrbs(obj) は、
%   代表BRB断面IDから対応するBRB断面IDへのマッピング配列を返します。
%   各代表BRB断面に対して最初のBRB断面IDを返します。
%
%   出力引数:
%     idrepbrbs2brbs - 代表BRB断面→BRB断面 [nrepbrbs×1]
%
%   参考:
%     mapBrbsToRepresentative, mapRepresentativeToWfs, mapRepresentativeToHss

% BRB断面の代表断面を取得
[~, idrepbrbs2brbs] = unique(obj.idsec2srep_(obj.idsec2stype_ == PRM.BRB));

return
end