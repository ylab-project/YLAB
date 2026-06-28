function [zcoord, zcoord_standard, idz_coord] = calc_story_zcoord(...
  floor, story, baseline, gl_to_first_floor_height)
%calc_story_zcoord - GL基準の標準階高座標と構造心座標を計算
%
%   [zcoord, zcoord_standard, idz_coord] = calc_story_zcoord(
%     floor, story, baseline, gl_to_first_floor_height) は、
%   標準階高の累積座標 zcoord_standard と、梁心との差を考慮した
%   構造心座標 zcoord をGL基準で計算する。

idfl2z = floor.idz;
[~, idsort] = sort(idfl2z);
idz_coord = [1; idfl2z(idsort)];

nz = size(baseline.z, 1);
zcoord_standard = zeros(nz, 1);
zcoord = zeros(nz, 1);

zstandard_seq = gl_to_first_floor_height ...
  + calculate_coord(floor.standard_height(idsort));
zstruct_seq = gl_to_first_floor_height ...
  + calculate_coord(floor.height(idsort));
delta_seq = zstruct_seq - zstandard_seq;
zcoord_standard(idz_coord) = zstandard_seq;

if istable(story)
  story_variables = story.Properties.VariableNames;
  has_delta = ismember('delta_height', story_variables);
  has_direct = ismember('diff_height_direct', story_variables);
else
  has_delta = isfield(story, 'delta_height');
  has_direct = isfield(story, 'diff_height_direct');
end

if has_delta || has_direct
  for i = 1:length(idz_coord)
    istory = find(story.idz == idz_coord(i), 1);
    if isempty(istory)
      continue
    end
    if has_delta
      delta_seq(i) = story.delta_height(istory);
    elseif ~isnan(story.diff_height_direct(istory))
      delta_seq(i) = story.diff_height_direct(istory);
    end
  end
end
zcoord(idz_coord) = zstandard_seq + delta_seq;

return
end