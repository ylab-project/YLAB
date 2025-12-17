function [zcoord, nodez, lm] = update_zcoord(...
  flh, idfl2z, idm2n, baseline, node)
%UPDATE_ この関数の概要をここに記述
%   詳細説明をここに記述

% node = com.node;
nodex = node.x;
nodey = node.y;
nodez = node.z;
zcoord = baseline.z.coord;

% Z座標の更新
[~,iddd] = sort(idfl2z);
zcoord_ = calculate_coord(flh(iddd));
zcoord([1; idfl2z]) = zcoord_;

%TODO FLOORではなくSTORYへ
% 節点座標への反映
nfl = size(flh,1);
for ifl=1:nfl
  nodez(node.idz==idfl2z(ifl)) = ...
    zcoord(idfl2z(ifl))+node.dz(node.idz==idfl2z(ifl));
end

% とりあえず
nodez(node.idz==1) = zcoord(1)+node.dz(node.idz==1);

% 部材長さへの反映
lm = sqrt((nodex(idm2n(:,2))-nodex(idm2n(:,1))).^2 ...
  +(nodey(idm2n(:,2))-nodey(idm2n(:,1))).^2 ...
  +(nodez(idm2n(:,2))-nodez(idm2n(:,1))).^2);
end

