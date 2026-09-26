function [Aeff, Asceff, Aqyeff, Aqzeff, Zyeff, Zzeff] = ...
  calc_effective_stress_secprop(A, Asc, Aqy, Aqz, Zy, Zz, ...
  secdim, stype, F)
%calc_effective_stress_secprop - 応力度用有効断面性能を計算する
%
%   [Aeff, Asceff, Aqyeff, Aqzeff, Zyeff, Zzeff] =
%     calc_effective_stress_secprop(A, Asc, Aqy, Aqz, Zy, Zz,
%     secdim, stype, F) は、元断面性能から許容応力度計算および
%     S柱断面算定表表示に用いる有効断面性能を返す。角形鋼管は
%     幅厚比が制限を超える部分を無効として控除する（付録1.7）。
%
%   入力引数:
%     A, Asc   - 断面積、軸応力度用断面積 [n×1]
%     Aqy, Aqz - 局所y・z方向せん断力に対する断面積 [n×1]
%     Zy, Zz   - 検定位置の局所y・z軸まわり断面係数 [n×1]
%     secdim   - 断面寸法 [n×ndim]
%     stype    - 断面種別 [n×1]
%     F        - 基準強度 [n×1]
%
%   出力引数:
%     Aeff, Asceff, Aqyeff, Aqzeff, Zyeff, Zzeff
%              - 有効断面性能 [n×1]（入力と同じ順）

Aeff = A;
Asceff = Asc;
Aqyeff = Aqy;
Aqzeff = Aqz;
Zyeff = Zy;
Zzeff = Zz;

stype = stype(:);
ihss = stype == PRM.HSS;
if any(ihss)
  [Aeff_hss, Aw_eff_hss, Z_eff_hss] = calc_effective_prop_hss(...
    secdim(ihss, :), F(ihss));
  Aeff(ihss) = Aeff_hss;
  Asceff(ihss) = Aeff_hss;
  Aqyeff(ihss) = Aw_eff_hss;
  Aqzeff(ihss) = Aw_eff_hss;
  Zyeff(ihss) = Z_eff_hss;
  Zzeff(ihss) = Z_eff_hss;
end

return
end

% -------------------------------------------------------------------------
function [Aeff, Aweff, Zeff] = calc_effective_prop_hss(secdim, F)
%calc_effective_prop_hss - 角形鋼管の有効断面性能を計算する

prop_full = calc_prop_hss(secdim);

D = secdim(:, 1);
t = secdim(:, 2);
r = secdim(:, 3);
F = F(:);

% SS7計算編付録1.7: r=0 の角形鋼管では式中の r を t とする。
r_eff = r;
r_eff(r_eff == 0) = t(r_eff == 0);

invalid = D - 2 * r_eff - t .* 1.6 .* sqrt(PRM.ES ./ F);
invalid = max(invalid, 0);

z0 = D / 2 - t / 2;
Iy_loss = 2 * (invalid .* t .^ 3 / 12 + invalid .* t ...
  .* z0 .^ 2) + 2 * (t .* invalid .^ 3 / 12);

Aeff = prop_full(:, 1) - 4 * t .* invalid;
Aweff = prop_full(:, 12) - 2 * t .* invalid;
Zeff = (prop_full(:, 4) - Iy_loss) ./ (D / 2);

return
end
