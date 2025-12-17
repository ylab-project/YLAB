function felement = update_felement(...
  felement, ar, cxl, cyl, idnode2dof, idmem2node)
%UPDATE_FELEMENT この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
[ndf,nlc] = size(felement);
nm = size(ar,1);
felement = zeros(ndf,nlc);

% 部材座標第3軸
czl = cross(cxl, cyl, 2);

% 要素荷重のセット
%   ar: 要素座標系
%   felement: 全体座標系
%   座標変換行列は{F}=[T]^T{f}
iddd = 1:nm;
for ilc=1:nlc
  istarget = any(ar(:,:,ilc)~=0,2);
  immm = iddd(istarget);
  for im = immm
    arunit = ar(im,:,ilc)';
    tt = [cxl(im,:)' cyl(im,:)' czl(im,:)'];
    ns = idnode2dof(idmem2node(im,1),:);
    felement(ns,ilc) = felement(ns,ilc) ...
      +[tt*arunit(1:3); tt*arunit(4:6)];
    ne = idnode2dof(idmem2node(im,2),:);
    felement(ne,ilc) = felement(ne,ilc) ...
      +[tt*arunit(7:9); tt*arunit(10:12)];
  end
end

return
end
