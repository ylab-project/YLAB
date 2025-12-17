function [conhgap, Hgap] = calc_girder_height_gap_var(...
  xvar, idHgap2var, options)

% 計算の準備
reqHgap = options.reqHgap;
tolHgap = options.tolHgap;

% 梁せい差の計算
Hgap = abs(xvar(idHgap2var(:,1))-xvar(idHgap2var(:,2)))';
Hgap(Hgap<=tolHgap) = reqHgap;

conhgap = 1-Hgap(:)/reqHgap;
return
end

