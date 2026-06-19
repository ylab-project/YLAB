function [cxl, cyl] = ...
  update_member_cosine(member_girder, member_column, ...
  member_brace, member_horizontal_brace, node)
%update_member_cosine - 現在の節点座標から部材方向余弦を計算
%
%   [cxl, cyl] = update_member_cosine(...) は、全体部材IDに対応する
%   [nme×3] の方向余弦配列を返す。

% 共通配列
x = node.x;
y = node.y;
z = node.z;

% --- 梁 ---
% 節点番号
idnode1 = member_girder.idnode1;
idnode2 = member_girder.idnode2;

% 断面（強軸）の角度
angle = member_girder.angle;

% 方向余弦の計算
an = deg2rad(angle);
[gcyl, gcxl] = ystar(x(idnode1), y(idnode1), z(idnode1), ...
  x(idnode2), y(idnode2), z(idnode2), an);

% --- 柱 ---
% 節点番号
idnode1 = member_column.idnode1;
idnode2 = member_column.idnode2;

% 断面（強軸）の角度
angle = member_column.angle;

% 方向余弦の計算
an = deg2rad(angle);
[ccyl, ccxl] = ystar(x(idnode1), y(idnode1), z(idnode1), ...
  x(idnode2), y(idnode2), z(idnode2), an);

% --- ブレース ---
% 節点番号
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

% 方向余弦の計算
an = zeros(length(idnode1),1);
[bcyl, bcxl] = ystar(x(idnode1), y(idnode1), z(idnode1), ...
  x(idnode2), y(idnode2), z(idnode2), an);

% --- 水平ブレース ---
% 節点番号
idnode1 = member_horizontal_brace.idnode1;
idnode2 = member_horizontal_brace.idnode2;

% 方向余弦の計算
an = zeros(length(idnode1),1);
[hbcyl, hbcxl] = ystar(x(idnode1), y(idnode1), z(idnode1), ...
  x(idnode2), y(idnode2), z(idnode2), an);

nme = max([member_girder.idme; member_column.idme; ...
  member_brace.idme; member_horizontal_brace.idme]);
cxl = zeros(nme, 3);
cyl = zeros(nme, 3);
cxl(member_girder.idme, :) = gcxl;
cyl(member_girder.idme, :) = gcyl;
cxl(member_column.idme, :) = ccxl;
cyl(member_column.idme, :) = ccyl;
cxl(member_brace.idme, :) = bcxl;
cyl(member_brace.idme, :) = bcyl;
cxl(member_horizontal_brace.idme, :) = hbcxl;
cyl(member_horizontal_brace.idme, :) = hbcyl;

return
end
