function [Asygm, gphiQ] = calc_composite_girder_Asy(...
  member_girder, ~, msprop, idmg2m)
%calc_composite_girder_Asy - 床によるせん断断面積の増大率を計算
%
%   [Asygm, gphiQ] = calc_composite_girder_Asy(
%     member_girder, ~, msprop, idmg2m) は、
%   スラブ協力幅からせん断断面積の増大率 gphiQ を計算する。
%   SS7マニュアル 3.2.2 式(3.4) に基づく。
%
%   入力引数:
%     member_girder - 梁部材情報（slab_width等）
%     msdim         - 部材要素の断面寸法 [nme×ncol]
%     msprop        - 部材要素の断面性能（構造体）
%     idmg2m        - 梁部材→部材要素のインデックス
%
%   出力引数:
%     Asygm - 合成後のせん断断面積 [nmg×1]
%     gphiQ - せん断断面積の増大率 [nmg×1]

nmeg = length(idmg2m);
kappa = 1.2;

% 原断面のAsy
Asy0 = msprop.Asy(idmg2m);
gphiQ = ones(nmeg, 1);

% RC梁のスラブ寄与
mgstype = member_girder.section_type;
isrc = (mgstype == PRM.RCRS);

ba = member_girder.slab_width;      % [nmg×2]
t = member_girder.slab_thickness;   % [nmg×2]

% スラブ部分のAs = ba*t/kappa（左右それぞれ）
Asy_slab = (ba(:,1).*t(:,1) + ba(:,2).*t(:,2)) / kappa;

% φQ = (Asy0 + Asy_slab) / Asy0
valid = isrc & Asy0 > 0;
gphiQ(valid) = (Asy0(valid) + Asy_slab(valid)) ./ Asy0(valid);

% 合成後のAsy
Asygm = Asy0 .* gphiQ;

return
end
