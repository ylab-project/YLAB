function [conjbs, jbsratio, idjbs] = ...
  calc_joint_bearing_strength_std(...
  sdimg, Zpyg, Fg, grade, sigu_col, isjbs, options)
%calc_joint_bearing_strength_std - 保有耐力接合（仕口）制約計算（基準式）
%   SS7マニュアル式6.60〜6.64に基づく。
%   第4引数は梁の鋼種 grade（PRM.GRADE_SS/SN/SM）。
%   入力は名目梁単位 [nng×...]。
%   conjbs [n_target×1]（isjbs対象のみに圧縮）、
%   jbsratio [nng×2]（左右端別、対象外は0）、
%   idjbs [n_target×1] = find(any(isjbs,2))。
%   isjbsが空のときは conjbs[nng×1], idjbs=[] を返す（早期return）。

% 計算の準備
ng = size(sdimg,1);
sigu_b = zeros(ng,1);
sigu_b(Fg==235 | Fg==295) = 400;
sigu_b(Fg==325) = 490;

% α（jbs_alpha_typeに応じて）[ng×1]
%   AIJ指針: 鋼種別（SS400=1.40, SN400B/C=1.30,
%     SM490=1.35, SN490B/C=1.25）。
%   基準解説書: 400N級一律1.30、490N級一律1.20。
alfa = zeros(ng,1);
is400 = (Fg==235 | Fg==295);
is490 = (Fg==325);
if options.jbs_alpha_type == PRM.JBS_AIJ
  alfa(is400 & grade==PRM.GRADE_SN) = 1.30;
  alfa(is400 & grade~=PRM.GRADE_SN) = 1.40;
  alfa(is490 & grade==PRM.GRADE_SN) = 1.25;
  alfa(is490 & grade~=PRM.GRADE_SN) = 1.35;
else
  alfa(is400) = 1.30;
  alfa(is490) = 1.20;
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
  idjbs = [];
  return
end
ratio(~isjbs) = 0;
jbsratio = ratio;
jbsratio(~any(isjbs, 2), :) = 0;
istarget = any(isjbs, 2);
idjbs = find(istarget);
conjbs = max(ratio(istarget, :), [], 2) - 1 + ajbs;

return
end
