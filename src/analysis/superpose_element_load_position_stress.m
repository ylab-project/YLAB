function stress = superpose_element_load_position_stress(stress0, lcdir)
%superpose_element_load_position_stress - 位置応力を設計ケースへ重ねる
%
%   stress = superpose_element_load_position_stress(stress0, lcdir) は、
%   直接入力された名目梁の1/4位置曲げモーメントを長期・地震時設計
%   ケースへ線形に重ね、直接入力がない位置はNaNのまま保持する。
%
%   入力引数:
%     stress0 - 解析ケース別の位置応力と入力有無
%     lcdir   - 荷重ケース方向
%
%   出力引数:
%     stress - 設計ケースへ重ねた位置応力と入力有無

values = stress0.M;
values(isnan(values)) = 0;
values = superpose_design_force(values, lcdir);
has_value = superpose_design_force(double(stress0.has_M), lcdir) > 0;
values(~has_value) = NaN;
stress.M = values;
stress.has_M = has_value;

return
end
