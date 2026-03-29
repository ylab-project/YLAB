function [conjbs, jbsratio] = calc_joint_bearing_strength_aij(...
  sdimg, Zpyg, Fg, m_num_col, isjbs, options)
%calc_joint_bearing_strength_aij - 保有耐力接合（仕口）制約計算（AIJ式）
%   鋼構造接合部設計指針式6.65に基づく。
%   第4引数は sigu_col ではなく m_num_col（mファクター分子）。
%   入力は名目梁単位 [nng×...]。
%   jbsratio [nng×2]（左右端別）、conjbs [nng×1]。

ng = size(sdimg, 1);
H = sdimg(:,1); B = sdimg(:,2);
tw = sdimg(:,3); tf = sdimg(:,4);
sc = options.girder_scallop_size;
ajbs = options.coptions.alfa_joint_bearing_strength;

% σfu（梁フランジσu）[ng×1]
sigu_f = zeros(ng, 1);
sigu_f(Fg==235 | Fg==295) = 400;
sigu_f(Fg==325) = 490;

% σwy（梁ウェブ降伏強度）[ng×1]
sigwy = Fg;

% α（jbs_alpha_typeに応じて）[ng×1]
alfa = zeros(ng, 1);
alfa(Fg==235 | Fg==295) = 1.30;
if options.jbs_alpha_type == PRM.JBS_AIJ
  alfa(Fg==325) = 1.25;
else
  alfa(Fg==325) = 1.20;
end

% Mfu = Af*db*σfu [ng×1]（フランジ寄与、端部によらない）
Mfu = B .* tf .* (H-tf) .* sigu_f;

% Zwpe = 0.25*tw*(H-2tf-2sc)^2 [ng×1]（スカラップ欠損考慮）
Zwpe = 0.25 .* tw .* (H - 2*tf - 2*sc).^2;

% m = min(1, 4*tcf/dj*sqrt(bj*σcy/(tbw*σwy))) [ng×2]
denom = (H - 2*tf) .* sqrt(tw .* sigwy);
if isempty(m_num_col)
  m = ones(ng, 2);
else
  m = min(1, [m_num_col(:,1)./denom, m_num_col(:,2)./denom]);
end

% Mwu = m*Zwpe*σwy [ng×2]（ウェブ寄与、端部ごとに異なる）
Mwu = [m(:,1).*Zwpe.*sigwy, m(:,2).*Zwpe.*sigwy];

% Mu = Mfu + Mwu [ng×2]
Mu = [Mfu+Mwu(:,1), Mfu+Mwu(:,2)];

% aMp = α*Zpy*F [ng×1]
aMp = alfa .* Zpyg .* Fg;

% ratio [ng×2]
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
