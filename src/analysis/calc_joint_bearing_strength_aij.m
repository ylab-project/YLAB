function Mu = calc_joint_bearing_strength_aij(sdimg, Fg, ...
  m_num_col, options)
%calc_joint_bearing_strength_aij - 接合部設計指針による最大曲げ強度
%
%   Mu = calc_joint_bearing_strength_aij(sdimg, Fg, m_num_col, options)
%   は、SS7計算編(6.65)～(6.67)式のMuを左右端ごとに求める。
%
%   入力引数:
%     sdimg - 梁断面寸法 [n×4以上] (mm)
%     Fg - 梁の基準強度 [n×1] (N/mm^2)
%     m_num_col - 角形鋼管柱のmファクター分子 [n×2]、空ならm=1
%     options - スカラップ寸法の指定
%
%   出力引数:
%     Mu - 左右端の最大曲げ強度 [n×2] (N mm)

H = sdimg(:,1); B = sdimg(:,2);
tw = sdimg(:,3); tf = sdimg(:,4);
sc = options.girder_scallop_size;
sigu_f = zeros(size(Fg));
sigu_f(Fg == 235 | Fg == 295) = 400;
sigu_f(Fg == 325) = 490;

% フランジ寄与とスカラップ欠損を考慮したウェブ塑性断面係数
Mfu = B .* tf .* (H-tf) .* sigu_f;
Zwpe = 0.25 .* tw .* (H - 2*tf - 2*sc).^2;
denom = (H - 2*tf) .* sqrt(tw .* Fg);
if isempty(m_num_col)
  m = ones(size(sdimg, 1), 2);
else
  m = min(1, m_num_col ./ denom);
end
Mu = Mfu + m .* (Zwpe .* Fg);

return
end