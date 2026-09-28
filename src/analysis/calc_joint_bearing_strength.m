function [conjbs, jbsratio, idjbs] = calc_joint_bearing_strength( ...
  sdimg, Zpyg, Fg, grade, sigu_col, m_num_col, is_tube, isjbs, options)
%calc_joint_bearing_strength - 梁端別に仕口の保有耐力接合を検定する
%
%   [conjbs, jbsratio, idjbs] = calc_joint_bearing_strength( ...
%     sdimg, Zpyg, Fg, grade, sigu_col, m_num_col, ...
%     is_tube, isjbs, options) は、梁端の柱形状に応じてMuとαを選ぶ。
%   解析・候補制限・復元に共通の数値計算と対象端の圧縮を行う。
%
%   入力引数:
%     sdimg - 梁断面寸法 [n×4以上] (mm)
%     Zpyg - 梁の塑性断面係数 [n×1] (mm^3)
%     Fg - 梁の基準強度 [n×1] (N/mm^2)
%     grade - 梁の鋼種 [n×1]
%     sigu_col - 接続柱の引張強さ [n×2] (N/mm^2)、空なら制限なし
%     m_num_col - 接続柱のmファクター分子 [n×2]、空ならm=1
%     is_tube - 角形鋼管柱だけが接続する端 [n×2]
%     isjbs - 評価対象端 [n×2]、空なら両端を評価して圧縮しない
%     options - Mu・αの選択、スカラップ、制約余裕の指定
%
%   出力引数:
%     conjbs - 対象梁だけに圧縮した制約値 [ntarget×1]
%     jbsratio - 左右端のαMp/Mu [n×2]、対象外は0
%     idjbs - 対象梁の行番号 [ntarget×1]、isjbsが空なら空

% 対象端にH形鋼柱が含まれる場合は指定によらず基準解説書とする
Mu = calc_joint_bearing_strength_std(sdimg, Fg, sigu_col, options);
if options.jbs_mu_formula == PRM.JBS_AIJ && any(is_tube, 'all')
  Mu_aij = calc_joint_bearing_strength_aij(sdimg, Fg, m_num_col, options);
  Mu(is_tube) = Mu_aij(is_tube);
end

% αの選択はMuの選択と独立。鋼管以外では基準解説書の値を使う
is400 = Fg == 235 | Fg == 295;
is490 = Fg == 325;
alfa = zeros(size(Fg));
alfa(is400) = 1.30;
alfa(is490) = 1.20;
alfa_end = [alfa alfa];
if options.jbs_alpha_type == PRM.JBS_AIJ
  alfa(is400 & grade == PRM.GRADE_SN) = 1.30;
  alfa(is400 & grade ~= PRM.GRADE_SN) = 1.40;
  alfa(is490 & grade == PRM.GRADE_SN) = 1.25;
  alfa(is490 & grade ~= PRM.GRADE_SN) = 1.35;
  alfa = [alfa alfa];
  alfa_end(is_tube) = alfa(is_tube);
end

jbsratio = alfa_end .* (Zpyg .* Fg) ./ Mu;
ajbs = options.coptions.alfa_joint_bearing_strength;
if isempty(isjbs)
  conjbs = max(jbsratio, [], 2) - 1 + ajbs;
  idjbs = [];
  return
end
jbsratio(~isjbs) = 0;
idjbs = find(any(isjbs, 2));
conjbs = max(jbsratio(idjbs, :), [], 2) - 1 + ajbs;

return
end