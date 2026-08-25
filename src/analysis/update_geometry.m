function [mglevel, zcoord, nodez, cxl, cyl, lm, lf, lr, story, floor] = ...
  update_geometry(secdim, baseline, node, story, floor, ...
  section, member, cbs, options, idsup2n)
%update_geometry - 構造モデルの幾何学的特性を更新
%
%   [mglevel, zcoord, nodez, cxl, cyl, lm, lf, lr, story, floor] =
%     update_geometry(secdim, baseline, node, story, floor,
%     section, member, cbs, options, idsup2n) は、部材レベル、座標、
%   フェイス長、剛域長などの幾何学的特性を計算・更新する。
%
%   入力引数:
%     secdim   - 断面寸法 [nsec×ncol]
%     baseline - 基準線データ構造体
%     node     - 節点データ構造体
%     story    - 階データ構造体
%     floor    - 床データ構造体
%     section  - 断面データ構造体
%     member   - 部材データ構造体
%     cbs      - 基礎柱データ構造体
%     options  - オプション設定構造体
%     idsup2n  - 支点節点ID [nsup×1]
%
%   出力引数:
%     mglevel - 梁レベル調整値（下げが負） [nmeg×1]
%     zcoord  - 基準線Z座標配列
%     nodez   - 節点Z座標 [nnode×1]
%     cxl     - 部材の方向余弦（X方向） [nme×3]
%     cyl     - 部材の方向余弦（Y方向） [nme×3]
%     lm      - 部材長（構造心間距離） [nme×1]
%     lf      - フェイス長構造体
%               .girder  - 梁フェイス長 [nmeg×2]
%               .columnx - 柱X方向フェイス長 [nmec×2]
%               .columny - 柱Y方向フェイス長 [nmec×2]
%     lr      - 剛域長構造体
%               .girder  - 梁剛域長 [nmeg×2]
%               .columnx - 柱X方向剛域長 [nmec×2]
%               .columny - 柱Y方向剛域長 [nmec×2]
%               .columnn - 柱材軸方向剛域長 [nmec×2]
%     story   - 更新された階データ構造体
%     floor   - 更新された床データ構造体

%TODO update_geometry_zと統合する。
%---
% デフォルト引数
if nargin < 10
  idsup2n = [];
end

% 定数
nmec = length(member.column.idnode1);
nmeg = length(member.girder.idnode1);
nstory = size(story,1);

% 計算の準備
stype = section.property.type;
mtype = member.property.type;
mgstype = member.girder.section_type;
member_column = member.column;
member_girder = member.girder;
member_brace = member.brace;
member_horizontal_brace = member.horizontal_brace;
mglevel = member.girder.level;

% ID変換
idsc2s = section.column.idsec;
idscb2s = idsc2s(section.column_base.idsecc);
idsg2s = section.girder.idsec;
idm2n = [member.property.idnode1 member.property.idnode2];
idm2s = member.property.idsec;
idmc2s = idm2s(mtype==PRM.COLUMN);
idmc2st = member.column.idstory;
cz_std = member.column.cz_std;  % 通り心ベース方向余弦Z成分
mcstype = stype(idmc2s);  % 柱断面タイプ
idmc2sf1x = member.column.idsec_face1x;
idmc2sf2x = member.column.idsec_face2x;
idmc2sf1y = member.column.idsec_face1y;
idmc2sf2y = member.column.idsec_face2y;
idmc2mf1x = member.column.idmeg_face1x;
idmc2mf2x = member.column.idmeg_face2x;
idmc2mf1y = member.column.idmeg_face1y;
idmc2mf2y = member.column.idmeg_face2y;
idmg2st = member.girder.idstory;
idmg2sg = member.girder.idsecg;
idmg2m = member.girder.idme;
idmg2sfl = member.girder.idsec_facel;
idmg2sfr = member.girder.idsec_facer;
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

%---
% 構造階高の更新
if options.do_autoupdate_floor_height
  [floor.height, stdh] = calc_floor_height(secdim, story, floor, ...
    idmg2st, idmg2sg, idsg2s, idm2s, idmg2m, stype, ...
    mglevel, idmg2type);
  story.delta_height = stdh;
else
  stdh = story.girder_level;
  story.delta_height = stdh;
end
[zcoord, zcoord_standard, idz_coord] = calc_story_zcoord(...
  floor, story, baseline, options.gl_to_first_floor_height);
node.z = update_zcoord(zcoord, idz_coord, node);
node = update_brace_column_node_z(node, zcoord_standard, member_girder);
nodez = node.z;
lm = calc_member_length_from_node(node, idm2n);

% 方向余弦を現在の node 座標から常に計算
[cxl, cyl] = update_member_cosine(member_girder, member_column, ...
  member_brace, member_horizontal_brace, node);

% ブレース部材長の算出（構造心間の斜め距離）
lm_brace = calc_brace_length(member_brace, member_girder, node);
lm(mtype==PRM.BRACE) = lm_brace;

%---
% フェイス長の計算
lf.girder = zeros(nmeg,2);
lf.columnx = zeros(nmec,2);
lf.columny = zeros(nmec,2);
idmg2n = [member_girder.idnode1 member_girder.idnode2];
[idmc2sf1x_geo, idmc2sf2x_geo, idmc2sf1y_geo, idmc2sf2y_geo, ...
  idmc2mf1x_geo, idmc2mf2x_geo, idmc2mf1y_geo, idmc2mf2y_geo] = ...
  filter_column_face_girder_direction(member_girder, idmc2sf1x, ...
  idmc2sf2x, idmc2sf1y, idmc2sf2y, idmc2mf1x, idmc2mf2x, ...
  idmc2mf1y, idmc2mf2y);
gcxl = cxl(mtype == PRM.GIRDER, :);
gcyl = cyl(mtype == PRM.GIRDER, :);
if options.consider_allowable_stress_at_face
  lf.girder = comp_face_length_girder(secdim, idmg2sfl, ...
    idmg2sfr, idscb2s, cbs.Df, gcxl, gcyl, idmg2n, idsup2n);
  [lf.columnx, lf.columny] = comp_face_length_column(...
    secdim, stdh, member_column.idz, member_girder.level, stype, ...
    idmc2sf1x_geo, idmc2sf2x_geo, idmc2sf1y_geo, idmc2sf2y_geo, ...
    idmc2st, idmc2mf1x_geo, idmc2mf2x_geo, idmc2mf1y_geo, ...
    idmc2mf2y_geo, gcxl, gcyl, cz_std);
end

%---
% 剛域の計算
lr.girder = zeros(nmeg,2);
lr.columnx = zeros(nmec,2);
lr.columny = zeros(nmec,2);
lr.columnn = zeros(nmec,2);
if options.consider_rigid_zone
  % 梁外形
  sdimgm = secdim(idmg2sg,1:4);
  gdir = member.girder.idir;      % 梁方向
  % 柱剛域
  [lr.columnx, lr.columny] = calc_rigid_zone_column( ...
    secdim, stdh, member_girder.level, mgstype, idmc2mf1x_geo, ...
    idmc2mf2x_geo, idmc2mf1y_geo, idmc2mf2y_geo, idmc2st, ...
    idmg2sg, idsg2s, mcstype, idmc2s, cz_std);
  % 柱剛域（直接入力値で上書き）
  if isfield(member, 'column_rigid_zone_direct')
    rzd = member.column_rigid_zone_direct;
    % X方向
    mask_x = ~isnan(rzd.x);
    lr.columnx(mask_x) = rzd.x(mask_x);
    % Y方向
    mask_y = ~isnan(rzd.y);
    lr.columny(mask_y) = rzd.y(mask_y);
    % 材軸方向（自動計算値は0）
    mask_n = ~isnan(rzd.n);
    lr.columnn(mask_n) = rzd.n(mask_n);
  end
  % 梁剛域
  lr.girder = calc_rigid_zone_girder(mgstype, idmg2sfl, ...
    idmg2sfr, idscb2s, cbs.Df, sdimgm, secdim, stype, ...
    gdir, gcxl, idmg2n, idsup2n);
end

return
end
