function idwfs2repwfs = mapWfsToRepresentative(obj)
%mapWfsToRepresentative 全WFS断面の代表WFS断面IDマッピングを取得
%   idwfs2repwfs = mapWfsToRepresentative(obj) は、全WFS断面に対する
%   代表WFS断面IDマッピングを返します。
%
%   出力引数:
%     idwfs2repwfs - WFS断面→代表WFS断面IDマッピング [nwfs×1]
%
%   例:
%     idwfs2repwfs = mapper.mapWfsToRepresentative();
%
%   参考:
%     mapHssToRepresentative, mapSectionToWfs

if obj.nwfs == 0
  idwfs2repwfs = [];
  return;
end

% WFS断面のみを抽出してuniqueで代表断面への変換
[~, ~, idwfs2repwfs] = unique(obj.idsec2srep_(obj.idsec2stype_ == PRM.WFS));

return
end