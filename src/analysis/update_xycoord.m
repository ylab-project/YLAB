function [nodex, nodey] = update_xycoord(node, baseline)
%UPDATE_XYCOORD この関数の概要をここに記述
%   詳細説明をここに記述

% 共通定数
% nblx = size(baseline.x,1);
% nbly = size(baseline.y,1);
% nblz = size(baseline.z,1);

% 計算の準備
nodex = node.x;
nodey = node.y;

% 軸振れ
ndelta = size(baseline.delta,1);
for i=1:ndelta
  idx = baseline.delta.idx(i);
  idy = baseline.delta.idy(i);
  dx = baseline.delta.dx(i);
  dy = baseline.delta.dy(i);
  istarget = node.idx==idx&node.idy==idy;
  nodex(istarget) = nodex(istarget)+dx;
  nodey(istarget) = nodey(istarget)+dy;
end

% セットバック
nsetback = size(baseline.setback,1);
for i=1:nsetback
  idx = baseline.setback.idx(i);
  idy = baseline.setback.idy(i);
  idstory = baseline.setback.idstory(i);
  dx = baseline.setback.dx(i);
  dy = baseline.setback.dy(i);
  istarget = node.idx==idx&node.idy==idy&node.idstory==idstory;
  nodex(istarget) = nodex(istarget)+dx;
  nodey(istarget) = nodey(istarget)+dy;
end

return
end

