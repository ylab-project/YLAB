function stress = superpose_element_load_position_stress(stress0, lcdir)
%superpose_element_load_position_stress - 位置応力を設計ケースへ重ねる
%
%   stress = superpose_element_load_position_stress(stress0, lcdir) は、
%   直接入力された名目梁の1/4位置曲げモーメントを長期・地震時設計
%   ケースへ線形に重ね、直接入力がない位置はNaNのまま保持する。
%
%   入力引数:
%     stress0 - 解析ケース別の位置応力
%     lcdir   - 荷重ケース方向
%
%   出力引数:
%     stress - 設計ケースへ重ねた位置応力

values = stress0.M;
valid = ~isnan(values);
values(~valid) = 0;
values = superpose_design_force(values, lcdir);
valid = superpose_design_force(double(valid), lcdir) > 0;
values(~valid) = NaN;
stress.M = values;

return
end
