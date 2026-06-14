function [is_gx_member, is_gy_member] = expand_girder_direction_flags( ...
  nmember, idmg2m, is_gx_girder, is_gy_girder)
%expand_girder_direction_flags - 梁方向寄与フラグを部材配列へ展開

is_gx_member = false(nmember, 1);
is_gy_member = false(nmember, 1);
is_gx_member(idmg2m) = is_gx_girder;
is_gy_member(idmg2m) = is_gy_girder;

return
end
