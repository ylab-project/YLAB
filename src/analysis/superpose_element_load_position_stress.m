function stress = superpose_element_load_position_stress( ...
  stress0, lcdir, is_girder, n_beam)
%superpose_element_load_position_stress - 位置応力を設計ケースへ重ねる
%
%   stress = superpose_element_load_position_stress(stress0, lcdir,
%   is_girder, n_beam) は、解析ケース別の名目梁1/4・3/4位置応力を
%   長期・地震時設計ケースへ線形に重ねる。RC梁の位置Qには端部Qと
%   同じ割増率nを適用し、算出対象外の位置はNaNのまま保持する。
%
%   入力引数:
%     stress0   - 解析ケース別の位置応力
%     lcdir     - 荷重ケース方向
%     is_girder - 割増率を適用するRC梁の行マスク（省略可）
%     n_beam    - RC梁Qに適用する割増率（省略時=1.0）
%
%   出力引数:
%     stress - 設計ケースへ重ねた位置応力
if nargin < 3
  is_girder = [];
end
if nargin < 4 || isempty(n_beam)
  n_beam = 1.0;
end

values = stress0.M;
valid = ~isnan(values);
values(~valid) = 0;
values = superpose_design_force(values, lcdir);
valid = superpose_design_force(double(valid), lcdir) > 0;
values(~valid) = NaN;
stress.M = values;

values0 = stress0.Q;
valid0 = ~isnan(values0);
values0(~valid0) = 0;
values = superpose_design_force(values0, lcdir, is_girder, n_beam, 1:2);
valid = superpose_design_force(double(valid0), lcdir) > 0;
values(~valid) = NaN;
stress.Q = values;

return
end