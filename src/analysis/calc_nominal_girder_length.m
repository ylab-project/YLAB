function [lgm_nominal, lg_nominal] = ...
  calc_nominal_girder_length(nominal_girder, lgm)
%CALC_GIRDER_THROUGH_LENGTH この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
nng = size(nominal_girder,1);
lgm_nominal = lgm;
lg_nominal = zeros(nng,1);
idmg = nominal_girder.idmeg;

% 通し部材長さ
for i=1:nng
  ncol = nnz(idmg(i,:));
  iddd = idmg(i,1:ncol);
  l = sum(lgm(iddd));
  lgm_nominal(iddd) = l;
  lg_nominal(i) = l;
end

return
end

