function [zcoord, nodez, member_girder_level, story, floor] = ...
  update_geometry_z(secdim, baseline, node, story, floor, section, ...
  member, options)
%update_geometry_z - 断面に対応するZ座標・梁レベル・階高を求める
%
%   [zcoord, nodez, member_girder_level, story, floor] = ...
%     update_geometry_z(secdim, baseline, node, story, floor, ...
%     section, member, options) は、構造階高を
%   一度計算し、入力節点のZ座標を更新する。
%
%   入力引数:
%     secdim   - 評価する断面寸法 [nsec×7] (mm)
%     baseline - 基準線データ
%     node     - 節点データ
%     story    - 層データ
%     floor    - 階データ
%     section  - 断面データ
%     member   - 部材データ
%     options  - 解析オプション
%
%   出力引数:
%     zcoord               - 基準線のZ座標 (mm)
%     nodez                - 節点のZ座標 (mm)
%     member_girder_level  - 梁レベル調整値 (mm)
%     story                - 意匠階高からの調整値を更新した層データ
%     floor                - 構造階高を更新した階データ

%---
% 定数
nstory = size(story,1);

% 計算の準備
stype = section.property.type;
mglevel = member.girder.level;

% ID変換
idsg2s = section.girder.idsec;
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
member_girder_level = mglevel;

% 構造階高の更新
if options.do_autoupdate_floor_height
  [floor.height, stdh] = calc_floor_height(secdim, story, floor, ...
    idmg2st, idmg2sg, idsg2s, idm2s, idmg2m, stype, mglevel, ...
    idmg2type);
  story.delta_height = stdh;
else
  stdh = story.girder_level;
  story.delta_height = stdh;
end
[zcoord, ~, idz_coord] = calc_story_zcoord(floor, story, baseline, ...
  options.gl_to_first_floor_height);
node.z = update_zcoord(zcoord, idz_coord, node);
nodez = node.z;

return
end

