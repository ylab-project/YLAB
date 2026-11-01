function [cxl, cyl, lm, lf, lr] = update_geometry(secdim, node, story, ...
  section, member, cbs, options, idsup2n)
%update_geometry - 確定済みの座標から部材の幾何量を計算する
%
%   [cxl, cyl, lm, lf, lr] = update_geometry(secdim, node, story,
%     section, member, cbs, options, idsup2n) は、update_frame_dataで
%   確定した座標・階高・梁レベルを用い、方向余弦、部材長、
%   フェイス長および剛域長を計算する。
%
%   入力引数:
%     secdim  - 断面寸法 [nsec×ncol] (mm)
%     node    - 座標を確定した節点データ構造体
%     story   - 階高を確定した層データ構造体
%     section - 断面データ構造体
%     member  - 分割と梁レベルを確定した部材データ構造体
%     cbs     - 柱脚断面情報（calc_column_base_sectionの出力）
%     options - オプション設定構造体
%     idsup2n - 支点節点ID [nsup×1]（省略時は空配列）
%
%   出力引数:
%     cxl - 部材の方向余弦（X方向） [nme×3]
%     cyl - 部材の方向余弦（Y方向） [nme×3]
%     lm  - 部材長（構造心間距離） [nme×1] (mm)
%     lf  - 両端フェイス長の構造体 (mm)
%             .girder  - 梁 [nmeg×2]
%             .columnx - 柱X方向 [nmec×2]
%             .columny - 柱Y方向 [nmec×2]
%     lr  - 両端剛域長の構造体 (mm)
%             .girder  - 梁 [nmeg×2]
%             .columnx - 柱X方向 [nmec×2]
%             .columny - 柱Y方向 [nmec×2]
%             .columnn - 柱材軸方向 [nmec×2]

%---
% デフォルト引数
if nargin < 8
  idsup2n = [];
end

% 定数
nmec = length(member.column.idnode1);
nmeg = length(member.girder.idnode1);

% 計算の準備
stype = section.property.type;
mtype = member.property.type;
mgstype = member.girder.section_type;
member_column = member.column;
member_girder = member.girder;
member_brace = member.brace;
member_horizontal_brace = member.horizontal_brace;

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

% 分割区間でも接続RC梁と剛域直接入力は入力柱の両外端を基準にする。
idmc2input = (1:nmec)';
ids = member_column.type == PRM.COLUMN_FOR_BRACE_FOUNDATION;
idmc2input(ids) = member_column.idsplit(ids);
idbase = idmc2input;
ids = member_column.type(idbase) == PRM.COLUMN_FOR_BRACE_BODY;
idbase(ids) = member_column.idsplit(idbase(ids));
idmc2sf1x = idmc2sf1x(idbase, :);
idmc2sf1y = idmc2sf1y(idbase, :);
idmc2mf1x = idmc2mf1x(idbase, :);
idmc2mf1y = idmc2mf1y(idbase, :);
idmc2sf2x = idmc2sf2x(idmc2input, :);
idmc2sf2y = idmc2sf2y(idmc2input, :);
idmc2mf2x = idmc2mf2x(idmc2input, :);
idmc2mf2y = idmc2mf2y(idmc2input, :);
idmg2sg = member.girder.idsecg;
idmg2sfl = member.girder.idsec_facel;
idmg2sfr = member.girder.idsec_facer;

% 構造階高と接続節点はupdate_frame_dataで確定済み。
stdh = story.delta_height;
lm = calc_member_length_from_node(node, idm2n);

% 方向余弦を現在の node 座標から常に計算
[cxl, cyl] = update_member_cosine(member_girder, member_column, ...
  member_brace, member_horizontal_brace, node);

% ブレース部材長の算出（構造心間の斜め距離）
lm_brace = calc_brace_length(member_brace, node);
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
  lf.girder = comp_face_length_girder(secdim, stype, idmg2sfl, ...
    idmg2sfr, idscb2s, cbs.Df, gcxl, idmg2n, idsup2n);
  [lf.columnx, lf.columny] = comp_face_length_column(...
    secdim, stdh, member.column_input.idz(idmc2input, :), ...
    member_girder.level, stype, idmc2sf1x_geo, idmc2sf2x_geo, ...
    idmc2sf1y_geo, idmc2sf2y_geo, idmc2st, idmc2mf1x_geo, ...
    idmc2mf2x_geo, idmc2mf1y_geo, idmc2mf2y_geo, gcxl, gcyl, cz_std);
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
    rzd.x = rzd.x(idmc2input, :);
    rzd.y = rzd.y(idmc2input, :);
    rzd.n = rzd.n(idmc2input, :);
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

% 分割前の柱全長が剛域なら、分割区間の剛性増大とは区別して停止する。
% SS7計算編5.2.2のNo.X0203に対応する形状確定時の入力条件。
nmc = numel(member.column_input.idnode1);
L = lm(member_column.idme(1:nmc));
ids = find(member_column.type(1:nmc) == PRM.COLUMN_FOR_BRACE_BODY);
L(ids) = L(ids) + lm(member_column.idme(member_column.idsplit(ids)));
names = {'columnx', 'columny', 'columnn'};
for i = 1:numel(names)
  ic = find(sum(lr.(names{i})(1:nmc, :), 2) >= L, 1);
  if ~isempty(ic)
    directions = {'X', 'Y', '材軸'};
    throw_err('Geometry', 'ColumnFullyRigid', ic, ...
      member_column.floor_name{ic}, member_column.coord_name{ic, 1}, ...
      member_column.coord_name{ic, 2}, directions{i});
  end
end

% 元の柱の剛域と区間の重なりを配分し、残りを上側へ引き継ぐ。
ids = find(member_column.type ~= PRM.COLUMN_STANDARD);
ci = member.column_input;
for ic = ids'
  ipc = idmc2input(ic);
  % 区間端の位置は分割節点と同じ高さ比で柱軸上の長さに換算し、
  % 斜め柱でも剛域長と同じ軸方向の尺度で重なりを取る
  zbase = node.z(ci.idnode1(ipc));
  dz = node.z(ci.idnode2(ipc)) - zbase;
  s = (node.z(member_column.idnode1(ic)) - zbase) / dz * L(ipc);
  t = (node.z(member_column.idnode2(ic)) - zbase) / dz * L(ipc);
  % X・Y・軸剛域とX・Yフェイスを同じ区間の重なりで配分する
  r = [lr.columnx(ic, :); lr.columny(ic, :); lr.columnn(ic, :); ...
    lf.columnx(ic, :); lf.columny(ic, :)];
  r(:, 1) = max(0, min(t, r(:, 1)) - s);
  r(:, 2) = max(0, t - max(s, L(ipc) - r(:, 2)));
  lr.columnx(ic, :) = r(1, :);
  lr.columny(ic, :) = r(2, :);
  lr.columnn(ic, :) = r(3, :);
  lf.columnx(ic, :) = r(4, :);
  lf.columny(ic, :) = r(5, :);
end

return
end
