function [idsec1x, idsec2x, idsec1y, idsec2y, ...
  idmeg1x, idmeg2x, idmeg1y, idmeg2y] = ...
  filter_column_face_girder_direction(node, member_girder, ...
  idsec1x, idsec2x, idsec1y, idsec2y, ...
  idmeg1x, idmeg2x, idmeg1y, idmeg2y)
%filter_column_face_girder_direction - 方向矛盾梁を除外
%
%   [idsec1x, idsec2x, idsec1y, idsec2y, idmeg1x, idmeg2x,
%     idmeg1y, idmeg2y] = filter_column_face_girder_direction(...) は、
%   柱フェイス・剛域算定用の接続梁リストから、入力方向ラベルと
%   同一化後の実配置が矛盾する梁を除外する。

% 幾何判定の許容差
tol = 1e-6;

% 同一化後の梁端点差
idnode1 = member_girder.idnode1;
idnode2 = member_girder.idnode2;
dx = node.x(idnode2) - node.x(idnode1);
dy = node.y(idnode2) - node.y(idnode1);

is_xy = member_girder.is_gx & member_girder.is_gy;
girderDir = member_girder.idir;
girderDir(is_xy) = PRM.XY;

% X方向リスト: 入力XラベルでY差を持つ梁のみ除外
[idmeg1x, idsec1x] = filter_column_face_list( ...
  idmeg1x, idsec1x, PRM.X, dy, tol, girderDir);
[idmeg2x, idsec2x] = filter_column_face_list( ...
  idmeg2x, idsec2x, PRM.X, dy, tol, girderDir);

% Y方向リスト: 入力YラベルでX差を持つ梁のみ除外
[idmeg1y, idsec1y] = filter_column_face_list( ...
  idmeg1y, idsec1y, PRM.Y, dx, tol, girderDir);
[idmeg2y, idsec2y] = filter_column_face_list( ...
  idmeg2y, idsec2y, PRM.Y, dx, tol, girderDir);

return
end
