function coord_shift = calc_baseline_coord_shift(baseline, span)
%calc_baseline_coord_shift - 構造心と通り心のズレを算出
%
%   coord_shift = calc_baseline_coord_shift(baseline, span) は、
%   構造心座標 baseline.x/y.coord と標準スパンから求めた通り心
%   座標との差を返す。K形分割等で末尾に追加されたダミー通り
%   （標準スパンに対応がない行）はズレ0とする。
%
%   入力引数:
%     baseline - 通りデータ構造体（.x/.y.coord）
%     span     - スパンデータ
%
%   出力引数:
%     coord_shift - 構造心と通り心のズレ（.x [nblx×1], .y [nbly×1]）

coord_std = calc_baseline_coord_std(span);
coord_shift.x = zeros(size(baseline.x.coord));
coord_shift.y = zeros(size(baseline.y.coord));
real_x = ~baseline.x.isdummy;
real_y = ~baseline.y.isdummy;
coord_shift.x(real_x) = baseline.x.coord(real_x) - coord_std.x;
coord_shift.y(real_y) = baseline.y.coord(real_y) - coord_std.y;

return
end
