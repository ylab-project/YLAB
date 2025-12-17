function idrepwfs2wfs = mapRepresentativeToWfs(obj)
%mapRepresentativeToWfs 代表WFS断面からWFS断面への変換
%   idrepwfs2wfs = mapRepresentativeToWfs(obj) は、
%   代表WFS断面IDから対応するWFS断面IDへのマッピング配列を返します。
%   各代表WFS断面に対して最初のWFS断面IDを返します。
%
%   出力引数:
%     idrepwfs2wfs - 代表WFS断面→WFS断面 [nrepwfs×1]
%
%   参考:
%     mapWfsToRepresentative, mapRepresentativeToHss, mapRepresentativeToBrbs

% WFS断面の代表断面を取得
[~, idrepwfs2wfs] = unique(obj.idsec2srep_(obj.idsec2stype_ == PRM.WFS));

return
end