function [conhgapsec, Hgapsec] = calc_girder_height_gap_section(secdim, idHgap2sec, options)

% 計算の準備
reqHgap = options.reqHgap;
tolHgap = options.tolHgap;

% 梁せい差（実寸）の計算
Hgapsec = abs(secdim(idHgap2sec(:,1),1)-secdim(idHgap2sec(:,2),1));
Hgapsec(Hgapsec<=tolHgap) = reqHgap;

conhgapsec = 1-Hgapsec/reqHgap;
return
end

