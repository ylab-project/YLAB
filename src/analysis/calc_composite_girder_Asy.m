function [Asygm, gphiAs] = calc_composite_girder_Asy(...
  mg, ~, msprop, idmg2m, options)
%calc_composite_girder_Asy - 床組と直接指定を梁せん断断面積へ反映する
%
%   [Asygm, gphiAs] = calc_composite_girder_Asy(
%     member_girder, ~, msprop, idmg2m, options) は、RC梁の
%   スラブ協力幅と梁の剛度増減率で直接指定されたφAを、
%   せん断変形用断面積へ反映する。
%
%   入力引数:
%     mg      - 梁部材情報（slab_width, phiAs等）
%     msprop  - 部材要素の断面性能（構造体）
%     idmg2m  - 梁部材→部材要素のインデックス
%     options - 共通オプション
%
%   出力引数:
%     Asygm  - 床組・直接指定反映後のせん断断面積 [nmg×1]
%     gphiAs - せん断断面積の増大率 [nmg×1]

nmeg = length(idmg2m);
Asy0 = msprop.Asy(idmg2m);
gphiAs = ones(nmeg, 1);

switch options.rc_shear_area_type
  case PRM.RC_AREA_FLOOR_WALL
    mgstype = mg.section_type;
    isrc = (mgstype == PRM.RCRS);
    Aslab = calc_girder_slab_area(mg);
    valid = isrc & Asy0 > 0;
    gphiAs(valid) = (Asy0(valid) + Aslab(valid) ./ 1.2) ...
      ./ Asy0(valid);
  case {PRM.RC_AREA_WALL_ONLY, PRM.RC_AREA_SECTION_ONLY}
    % YLABではAに対する腰壁・垂壁は当面未対応。
  otherwise
    error('calc_composite_girder_Asy:InvalidRcAreaType', ...
      'せん断変形用Aの計算方法の指定が不正です: %g', ...
      options.rc_shear_area_type);
end

phiAs = mg.phiAs;
gphiAs(~isnan(phiAs)) = phiAs(~isnan(phiAs));
Asygm = Asy0 .* gphiAs;

return
end

function Aslab = calc_girder_slab_area(mg)
%calc_girder_slab_area - 梁に取り付く上下床スラブ面積を計算する
ba = mg.slab_width;
t = mg.slab_thickness;
ba_l = mg.slab_width_lower;
t_l = mg.slab_thickness_lower;

Aslab_upper = ba(:,1) .* t(:,1) + ba(:,2) .* t(:,2);
Aslab_lower = ba_l(:,1) .* t_l(:,1) + ba_l(:,2) .* t_l(:,2);
Aslab = Aslab_upper + Aslab_lower;

return
end
