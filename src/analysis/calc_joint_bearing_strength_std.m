function Mu = calc_joint_bearing_strength_std(sdimg, Fg, sigu_col, options)
%calc_joint_bearing_strength_std - 基準解説書による仕口の最大曲げ強度
%
%   Mu = calc_joint_bearing_strength_std(sdimg, Fg, sigu_col, options)
%   は、SS7計算編(6.62)～(6.64)式のMuを左右端ごとに求める。
%
%   入力引数:
%     sdimg - 梁断面寸法 [n×4以上] (mm)
%     Fg - 梁の基準強度 [n×1] (N/mm^2)
%     sigu_col - 接続柱の引張強さ [n×2] (N/mm^2)、空なら制限なし
%     options - スカラップ寸法の指定
%
%   出力引数:
%     Mu - 左右端の最大曲げ強度 [n×2] (N mm)

sigu_b = zeros(size(Fg));
sigu_b(Fg == 235 | Fg == 295) = 400;
sigu_b(Fg == 325) = 490;
H = sdimg(:,1); B = sdimg(:,2);
tw = sdimg(:,3); tf = sdimg(:,4);
sc = options.girder_scallop_size;

% すみ肉溶接と母材の塑性断面係数の小さい方を採用する
s = min(12, max(6, 0.7*tw));
le = H - 2*tf - 2*sc - 2*s;
Zu1 = B.*tf.*(H-tf) + 0.25*sqrt(2/3)*(s.*le.^2);
Zu2 = B.*tf.*(H-tf) + 0.25*tw.*(H-2*tf).^2;
Zu = min(Zu1, Zu2);

% 柱材と梁フランジの引張強さの小さい方で評価する
sigu = [sigu_b sigu_b];
if ~isempty(sigu_col)
  sigu = min(sigu, sigu_col);
end
Mu = Zu .* sigu;

return
end