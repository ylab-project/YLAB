function [maxvio, idmaxvio, idmaxvioc, category] = ...
  extract_convio(ncon, ccon, tau, cvec)
%OBTAIN_CONVIO この関数の概要をここに記述
%   詳細説明をここに記述

[maxvio, idmaxvio] = max(cvec);
if (maxvio>tau)
  ncategory = [0 cumsum(ncon)];
  idcategory = 0:length(ncon);
  idcategory = min(idcategory(idmaxvio<=ncategory));
  idmaxvioc = idmaxvio-ncategory(idcategory);
  category = ccon{idcategory};
else
  idmaxvio = 0;
  category = '許容';
  idmaxvioc = 0;
end
end

