function coord_std = calc_baseline_coord_std(span)
%calc_baseline_coord_std - 標準スパンから通り心座標を生成
%
%   coord_std = calc_baseline_coord_std(span) は、
%   span.x/y.standard_span の累積値から標準座標を生成する。
%   baseline や node には標準座標を保持しない。
%
%   入力引数:
%     span      - スパンデータ
%
%   出力引数:
%     coord_std - 標準座標構造体（.x, .y）

coord_std.x = calculate_coord(span.x.standard_span);
coord_std.y = calculate_coord(span.y.standard_span);

return
end
