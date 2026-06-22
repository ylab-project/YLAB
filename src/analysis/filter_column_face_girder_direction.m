function [idsec1x, idsec2x, idsec1y, idsec2y, ...
  idmeg1x, idmeg2x, idmeg1y, idmeg2y] = ...
  filter_column_face_girder_direction(member_girder, ...
  idsec1x, idsec2x, idsec1y, idsec2y, ...
  idmeg1x, idmeg2x, idmeg1y, idmeg2y)
%filter_column_face_girder_direction - 幾何方向に合わない梁を除外
%
%   [idsec1x, idsec2x, idsec1y, idsec2y, idmeg1x, idmeg2x,
%     idmeg1y, idmeg2y] = filter_column_face_girder_direction(...) は、
%   柱フェイス・剛域算定用の接続梁リストから、節点同一化後の
%   幾何方向に合わない梁を除外する。

isxdir = member_girder.isxdir;
isydir = member_girder.isydir;

[idmeg1x, idsec1x] = filter_column_face_list( ...
  idmeg1x, idsec1x, isxdir);
[idmeg2x, idsec2x] = filter_column_face_list( ...
  idmeg2x, idsec2x, isxdir);

[idmeg1y, idsec1y] = filter_column_face_list( ...
  idmeg1y, idsec1y, isydir);
[idmeg2y, idsec2y] = filter_column_face_list( ...
  idmeg2y, idsec2y, isydir);

return
end
