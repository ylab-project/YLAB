function [Asceff, Aqyeff, Aqzeff, Zyeff, Zzeff, Aeff, Zyceff, Zzceff] = ...
  calc_effective_stress_secprop(msprop, msdim, mstype, options)
%calc_effective_stress_secprop - 応力度の計算に用いる断面性能を決める
%
%   [Asceff, Aqyeff, Aqzeff, Zyeff, Zzeff, Aeff, Zyceff, Zzceff] =
%     calc_effective_stress_secprop(msprop, msdim, mstype, options) は、
%   部材ごとに材端部と中央部の応力度計算に用いる断面性能を返す。
%   H形鋼の断面係数は「曲げの設計におけるウェブの考慮」の指定
%   （入力編2.5.4。梁は端部と中央部、柱は1つの指定）に従い、材端部は
%   ウェブ考慮ならスカラップ欠損を控除したウェブ込み、非考慮なら
%   フランジのみの値を用いる（計算編6.4.1・6.5.1）。中央部はスカラップ
%   欠損を控除しない（付録1.1(7)）。角形鋼管とH形鋼柱は、幅厚比が
%   規定値を超える部分を無効として控除する（付録1.7）。H形鋼梁の
%   控除は対象外とする。
%
%   入力引数:
%     msprop  - 部材断面性能の構造体（A, Asc, Aqy, Aqz, Zy, Zz, Zysc,
%               Zzsc, Zyf, Zzf, F を用いる）
%     msdim   - 部材の断面寸法 [nme×ndim]
%     mstype  - 部材の断面種別 [nme×1]
%     options - 計算オプション（consider_web_at_girder_end,
%               consider_web_at_girder_center, consider_web_at_column）
%
%   出力引数:
%     Asceff, Aqyeff, Aqzeff, Zyeff, Zzeff
%             - 材端部の軸応力度用断面積、局所y・z方向せん断力に対する
%               断面積、局所y・z軸まわり断面係数 [nme×1]
%     Aeff, Zyceff, Zzceff
%             - 中央部の断面積と局所y・z軸まわり断面係数 [nme×1]

% 計算の準備
mstype = mstype(:);
is_h_girder = mstype == PRM.WFS;
is_h_column = mstype == PRM.CWFS | mstype == PRM.CWFSI;
is_h = is_h_girder | is_h_column;

% 曲げの設計におけるウェブの考慮。梁は材端部と中央部で指定が分かれ、
% 柱は1つの指定に従う
consider_web_column = is_h_column & options.consider_web_at_column;
consider_web_end = (is_h_girder & options.consider_web_at_girder_end) ...
  | consider_web_column;
consider_web_center = (is_h_girder ...
  & options.consider_web_at_girder_center) | consider_web_column;

% 材端部の断面係数。ウェブ考慮ならスカラップ欠損を控除したウェブ込み、
% 非考慮ならフランジのみ
use_flange_end = is_h & ~consider_web_end;
Zyeff = msprop.Zy;
Zzeff = msprop.Zz;
Zyeff(consider_web_end) = msprop.Zysc(consider_web_end);
Zzeff(consider_web_end) = msprop.Zzsc(consider_web_end);
Zyeff(use_flange_end) = msprop.Zyf(use_flange_end);
Zzeff(use_flange_end) = msprop.Zzf(use_flange_end);

% 中央部の断面係数。スカラップ欠損は控除しない
use_flange_center = is_h & ~consider_web_center;
Zyceff = msprop.Zy;
Zzceff = msprop.Zz;
Zyceff(use_flange_center) = msprop.Zyf(use_flange_center);
Zzceff(use_flange_center) = msprop.Zzf(use_flange_center);

% 断面積は材端部がスカラップ考慮、中央部が全断面
Asceff = msprop.Asc;
Aqyeff = msprop.Aqy;
Aqzeff = msprop.Aqz;
Aeff = msprop.A;
F = msprop.F;

% 角形鋼管の幅厚比の控除。正方形断面で軸によらず、断面積と断面係数は
% 材端部と中央部で同じ（Asc=A、Zy=Zz、Aqy=Aqz=Aw）
ihss = mstype == PRM.HSS;
if any(ihss)
  [Ahss, Awhss, Zhss] = calc_effective_prop_hss(msprop.A(ihss), ...
    msprop.Aqy(ihss), msprop.Zy(ihss), msdim(ihss, :), F(ihss));
  Asceff(ihss) = Ahss;
  Aeff(ihss) = Ahss;
  Aqyeff(ihss) = Awhss;
  Aqzeff(ihss) = Awhss;
  Zyeff(ihss) = Zhss;
  Zzeff(ihss) = Zhss;
  Zyceff(ihss) = Zhss;
  Zzceff(ihss) = Zhss;
end

% H形鋼柱の幅厚比の控除（表1.2、図1.12）。寸法はH/I共通のH・B・tw・
% tf・rで与え、強軸・弱軸で控除量を求めてから断面の向きで局所y・z軸に
% 割り当てる
if any(is_h_column)
  ic = find(is_h_column);
  H = msdim(ic, 1);
  B = msdim(ic, 2);
  tw = msdim(ic, 3);
  tf = msdim(ic, 4);
  r = msdim(ic, 5);
  sqrt_ef = sqrt(PRM.ES./F(ic));
  Hloss = max(H - 2*tf - 2*r - 1.6*tw.*sqrt_ef, 0);
  Bloss = max(B - 1.06*tf.*sqrt_ef, 0);
  Aloss = tw.*Hloss + 2*tf.*Bloss;
  Asceff(ic) = msprop.Asc(ic) - Aloss;
  Aeff(ic) = msprop.A(ic) - Aloss;

  % 無効部分の断面二次モーメント。ウェブは中央、フランジは左右端から
  % 控除し、ウェブ分はウェブ考慮の部材にだけ効く
  Is_loss_f = 2*Bloss.*(tf.^3/12 + tf.*(H-tf).^2/4);
  Is_loss_w = tw.*Hloss.^3/12;
  Iw_loss_f = tf.*(B.^3 - (B-Bloss).^3)/6;
  Iw_loss_w = Hloss.*tw.^3/12;
  Is_loss_end = Is_loss_f + Is_loss_w.*consider_web_end(ic);
  Iw_loss_end = Iw_loss_f + Iw_loss_w.*consider_web_end(ic);
  Is_loss_center = Is_loss_f + Is_loss_w.*consider_web_center(ic);
  Iw_loss_center = Iw_loss_f + Iw_loss_w.*consider_web_center(ic);

  % 強軸は局所y軸（CWFS）または局所z軸（CWFSI）。[n×2]の局所y・z列
  % から強軸側と弱軸側の要素を選ぶ添字を作る
  n = numel(ic);
  ii = mstype(ic) == PRM.CWFSI;
  istrong = sub2ind([n 2], (1:n)', 1 + ii);
  iweak = sub2ind([n 2], (1:n)', 2 - ii);

  % せん断面積。強軸と同じ側の列がフランジ方向のせん断面積
  % （calc_secprop でフランジ面積の2/3）で無効フランジ幅の分を、弱軸側
  % の列がウェブ方向のせん断面積で無効ウェブ高さの分を控除する
  Aq = [msprop.Aqy(ic) msprop.Aqz(ic)];
  Aq(istrong) = Aq(istrong) - 2*tf.*Bloss*2/3;
  Aq(iweak) = Aq(iweak) - tw.*Hloss;
  Aqyeff(ic) = Aq(:, 1);
  Aqzeff(ic) = Aq(:, 2);

  % 断面係数。強軸は無効部分の断面二次モーメントをせいの半分で除した
  % 分を控除し、弱軸は断面二次モーメントを有効幅の半分で除して求め直す
  Zend = [Zyeff(ic) Zzeff(ic)];
  Zend(istrong) = Zend(istrong) - Is_loss_end./(H/2);
  Zend(iweak) = (Zend(iweak).*B/2 - Iw_loss_end)./((B-Bloss)/2);
  Zyeff(ic) = Zend(:, 1);
  Zzeff(ic) = Zend(:, 2);
  Zc = [Zyceff(ic) Zzceff(ic)];
  Zc(istrong) = Zc(istrong) - Is_loss_center./(H/2);
  Zc(iweak) = (Zc(iweak).*B/2 - Iw_loss_center)./((B-Bloss)/2);
  Zyceff(ic) = Zc(:, 1);
  Zzceff(ic) = Zc(:, 2);
end

return
end

%--------------------------------------------------------------------------
function [Aeff, Aweff, Zeff] = calc_effective_prop_hss(A, Aw, Z, secdim, F)
%calc_effective_prop_hss - 角形鋼管の有効断面性能を計算する
%
%   [Aeff, Aweff, Zeff] = calc_effective_prop_hss(A, Aw, Z, secdim, F)
%   は、幅厚比の規定値を超える平板部分を断面積、せん断面積、断面係数
%   から控除する（付録1.7、表1.2）。
%
%   入力引数:
%     A, Aw, Z - 全断面の断面積、せん断面積、断面係数 [n×1]
%     secdim   - 断面寸法 [D, t, r, ...]
%     F        - 基準強度 [n×1]
%
%   出力引数:
%     Aeff  - 有効断面積 [mm2]
%     Aweff - せん断有効断面積 [mm2]
%     Zeff  - 有効断面係数 [mm3]

D = secdim(:, 1);
t = secdim(:, 2);
r = secdim(:, 3);
F = F(:);

% SS7計算編付録1.7: r=0の角形鋼管では式中のrをtとする。
r_eff = r;
r_eff(r_eff == 0) = t(r_eff == 0);
invalid = max(D - 2*r_eff - 1.6*t.*sqrt(PRM.ES./F), 0);
z0 = D/2 - t/2;
Iy_loss = 2*(invalid.*t.^3/12 + invalid.*t.*z0.^2) + 2*(t.*invalid.^3/12);
Aeff = A - 4*t.*invalid;
Aweff = Aw - 2*t.*invalid;
Zeff = Z - Iy_loss./(D/2);

return
end
