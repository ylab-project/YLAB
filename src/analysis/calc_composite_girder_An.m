function [Agm, gphiAn] = calc_composite_girder_An(...
  mg, msprop, idmg2m, options)
%calc_composite_girder_An - 床組と直接指定を梁軸断面積へ反映する
%
%   [Agm, gphiAn] = calc_composite_girder_An(
%     member_girder, msprop, idmg2m, options) は、RC梁の
%   スラブ協力幅と梁の剛度増減率で直接指定された材軸方向φAを、
%   軸変形用断面積へ反映する。
%
%   入力引数:
%     mg      - 梁部材情報（slab_width, phiAn等）
%     msprop  - 部材要素の断面性能（構造体）
%     idmg2m  - 梁部材→部材要素のインデックス
%     options - 共通オプション
%
%   出力引数:
%     Agm     - 床組・直接指定反映後の軸断面積 [nmg×1]
%     gphiAn  - 軸断面積の増大率 [nmg×1]

nmeg = length(idmg2m);
A0 = msprop.A(idmg2m);
gphiAn = ones(nmeg, 1);

switch options.rc_axial_area_type
  case PRM.RC_AREA_FLOOR_WALL_N
    mgstype = mg.section_type;
    isrc = (mgstype == PRM.RCRS);
    Aslab = calc_girder_slab_area(mg);
    valid = isrc & A0 > 0;
    gphiAn(valid) = (A0(valid) + Aslab(valid)) ./ A0(valid);
  case PRM.RC_AREA_SECTION_ONLY_N
    % 部材断面のみ。床・壁は考慮しない。
  otherwise
    error('calc_composite_girder_An:InvalidRcAreaType', ...
      '軸変形用Aの計算方法の指定が不正です: %g', ...
      options.rc_axial_area_type);
end

phiAn = mg.phiAn;
gphiAn(~isnan(phiAn)) = phiAn(~isnan(phiAn));
Agm = A0 .* gphiAn;

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
