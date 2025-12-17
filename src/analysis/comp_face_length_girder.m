function lfgirder = comp_face_length_girder(...
  secdim, idmg2sfl, idmg2sfr, idscb2s, cbsDf, cxl, cyl)
%UNTITLED この関数の概要をここに記述
%   詳細説明をここに記述

% 定数
nmg = size(idmg2sfl,1);

% 計算の準備
lfgirder = zeros(nmg,2);
czl = cross(cxl, cyl, 2);

% 梁の柱面長さ
for ig=1:nmg
  for ilr=1:2
    switch ilr
      case 1
        ids = idmg2sfl(ig,:);
      case 2
        ids = idmg2sfr(ig,:);
    end

    Df = 0;
    if any(ids>0)
      if any(ids(1)==idscb2s)
        Df = cbsDf(ids(1)==idscb2s);
      end
      sss = secdim(ids(ids>0),1);
      lfgirder(ig,ilr) = max([sss; Df])/2;

      % 投影長さ
      lfgirder(ig,ilr) = lfgirder(ig,ilr)/czl(ig,3);
    end
  end
end

return
end

