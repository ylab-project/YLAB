function [floor_height, story_delta_height] = calc_floor_height(...
  secdim, story, floor, idmg2st, idmg2sg, idsg2s, ...
  idm2s, idmg2m, stype, ...
  girder_level)
%COMP_FLOOR_HEIGHT この関数の概要をここに記述
%   詳細説明をここに記述

% 定数
nfl = size(floor,1);
nstory = nfl+1;
% ng = length(idsg2s);
nsec = size(secdim,1);
Hs = zeros(nsec,1);

% 共通配列
% idfl2s = floor.idstory;
floor_standard_height = floor.standard_height;
Hs(stype==PRM.WFS) = secdim(stype==PRM.WFS,1);
Hs(stype==PRM.RCRS) = secdim(stype==PRM.RCRS,2);
Hm = Hs(idm2s);
Hg = Hm(idmg2m);

% 階高と梁心の差（各階の梁せい平均の1/2）の計算
story_delta_height = zeros(nstory,1);
for ist = 1:nstory
  istarget = idmg2st==ist;
  if any(istarget)
    ggg = girder_level(istarget);
    % ggg(ggg==0) = story.girder_level(ist);
    dz = mean(Hg(istarget)/2-ggg);
    % dz = mean(Hg(istarget)/2-girder_level(istarget));
    story_delta_height(ist) = story_delta_height(ist)-dz;
  end
end

% 構造階高の計算
% ddd = story_delta_height+story.girder_level;
ddd = story_delta_height;
floor_height = floor_standard_height;
floor_height = floor_height+ddd(2:end);
floor_height = floor_height-ddd(1:end-1);
end

