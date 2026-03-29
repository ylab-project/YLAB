function [conjbs, jbsratio] = calc_joint_bearing_strength_std(...
  sdimg, Zpyg, Fg, sigu_col, isjbs, options)
%calc_joint_bearing_strength_std - 保有耐力接合（仕口）制約計算（基準式）
%   SS7マニュアル式6.60〜6.64に基づく。
%   入力は名目梁単位 [nng×...]。
%   jbsratio [nng×2]（左右端別）、conjbs [nng×1]。

% 計算の準備
ng = size(sdimg,1);
sigu_b = zeros(ng,1);
sigu_b(Fg==235 | Fg==295) = 400;
sigu_b(Fg==325) = 490;
alfa = zeros(ng,1);
alfa(Fg==235 | Fg==295) = 1.3;
if options.jbs_alpha_type == PRM.JBS_AIJ
  alfa(Fg==325) = 1.25;
else
  alfa(Fg==325) = 1.20;
end
H = sdimg(:,1); B = sdimg(:,2);
tw = sdimg(:,3); tf = sdimg(:,4);
sc = options.girder_scallop_size;
ajbs = options.coptions.alfa_joint_bearing_strength;

% 最大曲げ強度 Zu（断面共通）
s = 0.7*tw; s(s<6) = 6; s(s>12) = 12;
le = H-2*tf-2*sc-2*s;
Zu1 = B.*tf.*(H-tf) + 0.25*sqrt(2/3)*(s.*le.^2);
Zu2 = B.*tf.*(H-tf) + 0.25*tw.*(H-2*tf).^2;
Zu = min([Zu1 Zu2],[],2);

% 梁端ごとのσu・Mu（SS7式6.62）
% sigu_col: [ng×2] or empty
sigu = [sigu_b sigu_b];
if ~isempty(sigu_col)
  sigu = min(sigu, sigu_col);
end
Mu = [Zu.*sigu(:,1), Zu.*sigu(:,2)];

% 設計用曲げモーメント
aMp = alfa .* Zpyg .* Fg;

% 梁端ごとの比率
ratio = [aMp./Mu(:,1), aMp./Mu(:,2)];

% 対象端のみ評価（isjbsでマスク）
if isempty(isjbs)
  jbsratio = ratio;
  conjbs = max(ratio, [], 2) - 1 + ajbs;
  return
end
ratio(~isjbs) = 0;
jbsratio = ratio;
conjbs = max(ratio, [], 2) - 1 + ajbs;
istarget = any(isjbs, 2);
conjbs(~istarget) = -1;
jbsratio(~istarget, :) = 0;

return
end
