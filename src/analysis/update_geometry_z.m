function [zcoord, nodez, lm, ...
  member_girder_level, story_delta_height, floor_height] = ...
  update_geometry_z(secdim, baseline, node, story, floor, ...
  section, member, options)
%UPDATE_GEOMETRY この関数の概要をここに記述
%   詳細説明をここに記述

%---
% 定数
nstory = size(story,1);

% 計算の準備
stype = section.property.type;
mglevel = member.girder.level;

% ID変換
idfl2z = floor.idz;
idsg2s = section.girder.idsec;
idm2n = [member.property.idnode1 member.property.idnode2];
idm2s = member.property.idsec;
idmg2st = member.girder.idstory;
idmg2sg = member.girder.idsecg;
idmg2m = member.girder.idme;

% 梁のレベル調整
for ist = 1:nstory
  istarget = idmg2st==ist;
  if any(istarget)
    ggg = mglevel(istarget);
    ggg(ggg==0) = story.girder_level(ist);
  elseif ist == 1 
    % 基礎なしモデル
    continue
  else
    % 該当なし
    continue
  end
  mglevel(istarget) = ggg;
end

% 結果の保存
member_girder_level = mglevel;

% 構造階高の更新
if options.do_autoupdate_floor_height
  [flh, stdh] = calc_floor_height(...
    secdim, story, floor, idmg2st, idmg2sg, idsg2s, ...
    idm2s, idmg2m, stype, mglevel);
  [zcoord, nodez, lm] = update_zcoord(flh, idfl2z, idm2n, baseline, node);
else
  nodez = node.z;
  flh = floor.height;
  stdh = story.girder_level;
  story.delta_height = stdh;
end

% 結果の保存
floor_height = flh;
story_delta_height = stdh;
end

