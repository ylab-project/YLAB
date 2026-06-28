function sprop_eff = calc_effective_secprop_for_stress( ...
  sprop, secdim, stype)
%calc_effective_secprop_for_stress - 断面算定用有効断面性能を作成
%
%   sprop_eff = calc_effective_secprop_for_stress(sprop, secdim, stype)
%   は、剛性・重量用の全断面性能 sprop を元に、断面算定時の
%   応力度計算に用いる有効断面性能を返す。SS7計算編付録1.7に
%   従い、角形鋼管では幅厚比規定値を超えた平板中央部を無効と
%   みなす。未対応断面は全断面性能をそのまま用いる。

sprop_eff = sprop;
stype = stype(:);

ihss = stype == PRM.HSS;
if any(ihss)
  prop_hss = calc_effective_prop_hss(secdim(ihss, :), ...
    sprop.F(ihss));
  sprop_eff.A(ihss) = prop_hss(:, 1);
  sprop_eff.Asy(ihss) = prop_hss(:, 2);
  sprop_eff.Asz(ihss) = prop_hss(:, 3);
  sprop_eff.Zy(ihss) = prop_hss(:, 4);
  sprop_eff.Zz(ihss) = prop_hss(:, 5);
  sprop_eff.Aw(ihss) = prop_hss(:, 6);
  sprop_eff.Asc(ihss) = prop_hss(:, 1);
end

return
end

% -------------------------------------------------------------------------
function prop_eff = calc_effective_prop_hss(secdim, F)
%calc_effective_prop_hss - 角形鋼管の断面算定用有効断面性能

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
Iy_loss = 2 * (invalid .* t .^ 3 / 12 ...
  + invalid .* t .* z0 .^ 2) ...
  + 2 * (t .* invalid .^ 3 / 12);

A_eff = prop_full(:, 1) - 4 * t .* invalid;
Aw_eff = prop_full(:, 12) - 2 * t .* invalid;
Z_eff = (prop_full(:, 4) - Iy_loss) ./ (D / 2);

prop_eff = [A_eff, Aw_eff, Aw_eff, Z_eff, Z_eff, Aw_eff];

return
end
