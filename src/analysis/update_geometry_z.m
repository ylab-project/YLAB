function [zcoord, nodez, lm, member_girder_level, story_delta_height, ...
  floor_height] = update_geometry_z(secdim, baseline, ...
  node, story, floor, section, member, options)
%update_geometry_z - Z方向座標・梁レベル・階高の更新

%---
% 定数
nstory = size(story,1);

% 計算の準備
stype = section.property.type;
mtype = member.property.type;
member_girder = member.girder;
member_brace = member.brace;
mglevel = member.girder.level;

% ID変換
idsg2s = section.girder.idsec;
idm2n = [member.property.idnode1 member.property.idnode2];
idm2s = member.property.idsec;
idmg2st = member.girder.idstory;
idmg2sg = member.girder.idsecg;
idmg2m = member.girder.idme;
idmg2type = member.girder.type;

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
member_girder.level = mglevel;
member_girder_level = mglevel;

% 構造階高の更新
if options.do_autoupdate_floor_height
  [flh, stdh] = calc_floor_height(secdim, story, floor, idmg2st, ...
    idmg2sg, idsg2s, idm2s, idmg2m, stype, mglevel, ...
    idmg2type);
  story.delta_height = stdh;
else
  flh = floor.height;
  stdh = story.girder_level;
  story.delta_height = stdh;
end
[zcoord, zcoord_standard, idz_coord] = calc_story_zcoord(...
  floor, story, baseline, options.gl_to_first_floor_height);
node.z = update_zcoord(zcoord, idz_coord, node);
node = update_brace_column_node_z(node, zcoord_standard, member_girder);
nodez = node.z;
lm = calc_member_length_from_node(node, idm2n);
lm_brace = calc_brace_length(member_brace, member_girder, node);
lm(mtype == PRM.BRACE) = lm_brace;

% 結果の保存
floor_height = flh;
story_delta_height = stdh;

return
end

