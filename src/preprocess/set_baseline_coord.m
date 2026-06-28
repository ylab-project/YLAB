function baseline = set_baseline_coord(...
  baseline, span, floor, story, options, idstory2nominal)
%set_baseline_coord - 通り心座標を設定する
%
%   baseline = set_baseline_coord(
%     baseline, span, floor, story, options, idstory2nominal) は、
%   X/Y/Z通りの座標を計算し、Z通りにはGL基準の標準階高座標と
%   構造心座標を設定する。

baseline.x.coord = calculate_coord(span.x.span);
baseline.y.coord = calculate_coord(span.y.span);
[baseline.z.coord, baseline.z.coord_standard] = calc_story_zcoord(...
  floor, story, baseline, options.gl_to_first_floor_height);
baseline.z.isdummy = story.isdummy;
baseline.z.idnominal = idstory2nominal;

return
end