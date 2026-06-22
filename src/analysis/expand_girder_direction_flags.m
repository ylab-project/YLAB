function [isxdir_member, isydir_member] = ...
  expand_girder_direction_flags( ...
  nmember, idmg2m, isxdir_girder, isydir_girder)
%expand_girder_direction_flags - 梁方向寄与フラグを部材配列へ展開

isxdir_member = false(nmember, 1);
isydir_member = false(nmember, 1);
isxdir_member(idmg2m) = isxdir_girder;
isydir_member(idmg2m) = isydir_girder;

return
end
