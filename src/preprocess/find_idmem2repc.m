function idmem2repc = find_idmem2repc(Dn, tn, repc, idc2mem, nm)
%INVERSE_REPG この関数の概要をここに記述
%   詳細説明をここに記述

tmp = zeros(1,size(Dn,2));
Dg = Dn(repc);
tg = tn(repc);
for i=1:length(repc)
  tmp(Dn==Dg(i)&tn==tg(i)) = i;
end

iddd = 1:size(Dn,2);
idmem2repc = zeros(1,nm);
idmem2repc(idc2mem(iddd)) = tmp;
end

