function [conjbs, jbsratio] = calc_joint_bearing_strength(...
  sdimg, Zpyg, Fg, isjbs, options)
%CALC_JOINT_BEARING_STRENGTH この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
ng = size(sdimg,1);
sigu = zeros(ng,1); sigu(Fg==235) = 400; sigu(Fg==325) = 490;
alfa = zeros(ng,1); alfa(Fg==235) = 1.3; alfa(Fg==325) = 1.2;
H = sdimg(:,1);
B = sdimg(:,2);
tw = sdimg(:,3);
tf = sdimg(:,4);
sc = options.girder_scallop_size;
ajbs = options.coptions.alfa_joint_bearing_strength;
% conjbs = zeros(ng,1);

% 最大曲げ強度
s = 0.7*tw; s(s<6) = 6; s(s>12) = 12;
le = H-2*tf-2*sc-2*s;
Zu1 = B.*tf.*(H-tf)+0.25*sqrt(2/3)*(s.*le.^2);
Zu2 = B.*tf.*(H-tf)+0.25*tw.*(H-2*tf).^2;
Zu = min([Zu1 Zu2],[],2);
Mu = Zu.*sigu;

% 設計用曲げモーメント
Mp = Zpyg.*Fg;
aMp = alfa.*Mp;

% 制約値
conjbs = aMp./Mu-1+ajbs;
jbsratio = aMp./Mu;

% 両端ピン部材は除外→制約値を-1にセット
if isempty(isjbs)
  return
end
istarget = any(isjbs,2);
conjbs(~istarget) = -1;
jbsratio(~istarget) = 0;
end

