function [Agm, gphiAn] = calc_composite_girder_An(mg, msprop, idmg2m)
%calc_composite_girder_An - 床組由来の梁軸断面積増大率を計算する
%
%   [Agm, gphiAn] = calc_composite_girder_An(
%     member_girder, msprop, idmg2m) は、RC梁のスラブ協力幅から
%   軸変形用断面積の増大率を計算する。
%
%   入力引数:
%     mg      - 梁部材情報（slab_width等）
%     msprop  - 部材要素の断面性能（構造体）
%     idmg2m  - 梁部材→部材要素のインデックス
%
%   出力引数:
%     Agm     - 床組由来反映後の軸断面積 [nmg×1]
%     gphiAn  - 軸断面積の増大率 [nmg×1]

nmeg = length(idmg2m);
A0 = msprop.A(idmg2m);
gphiAn = ones(nmeg, 1);

mgstype = mg.section_type;
isrc = (mgstype == PRM.RCRS);

ba = mg.slab_width;
t = mg.slab_thickness;
ba_l = mg.slab_width_lower;
t_l = mg.slab_thickness_lower;

Aslab_upper = ba(:,1) .* t(:,1) + ba(:,2) .* t(:,2);
Aslab_lower = ba_l(:,1) .* t_l(:,1) + ba_l(:,2) .* t_l(:,2);
Aslab = Aslab_upper + Aslab_lower;
valid = isrc & A0 > 0;
gphiAn(valid) = (A0(valid) + Aslab(valid)) ./ A0(valid);

Agm = A0 .* gphiAn;

return
end

