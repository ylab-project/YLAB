function [Asygm, gphiAs] = calc_composite_girder_Asy(mg, ~, msprop, idmg2m)
%calc_composite_girder_Asy - 梁剛度直接指定のφAをAsへ反映する
%
%   [Asygm, gphiAs] = calc_composite_girder_Asy(
%     member_girder, ~, msprop, idmg2m) は、梁の剛度増減率で
%   直接指定されたφAをせん断変形用断面積へ反映する。
%
%   入力引数:
%     mg      - 梁部材情報（phiAs等）
%     msprop  - 部材要素の断面性能（構造体）
%     idmg2m  - 梁部材→部材要素のインデックス
%
%   出力引数:
%     Asygm  - 直接指定反映後のせん断断面積 [nmg×1]
%     gphiAs - せん断断面積の増大率 [nmg×1]

Asy0 = msprop.Asy(idmg2m);
gphiAs = mg.phiAs;
Asygm = Asy0 .* gphiAs;

return
end

