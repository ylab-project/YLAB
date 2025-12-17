function [lcm_nominal, lc_nominal] = ...
  calc_nominal_column_length(nominal_comumn, lcm)
%CALC_GIRDER_THROUGH_LENGTH この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
nnc = size(nominal_comumn,1);
lcm_nominal = lcm;
lc_nominal = zeros(nnc,1);
idmc = nominal_comumn.idmec;

% 通し部材長さ
for i=1:nnc
  ncol = nnz(idmc(i,:));
  iddd = idmc(i,1:ncol);
  l = sum(lcm(iddd));
  lcm_nominal(iddd) = l;
  lc_nominal(i) = l;
end

return
end

