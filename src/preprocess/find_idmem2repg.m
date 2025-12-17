function idmem2repg = find_idmem2repg(Hn, Bn, twn, tfn, repg, idg2mem, nm)
%find_idmem2repg この関数の概要をここに記述
%   詳細説明をここに記述

tmp = zeros(1,size(Hn,2));
Hg = Hn(repg);
Bg = Bn(repg);
twg = twn(repg);
tfg = tfn(repg);
for i=1:length(repg)
  tmp(Hn==Hg(i)&Bn==Bg(i)&twn==twg(i)&tfn==tfg(i)) = i;
end

iddd = 1:size(Hn,2);
idmem2repg = zeros(1,nm);
idmem2repg(idg2mem(iddd)) = tmp;
end
