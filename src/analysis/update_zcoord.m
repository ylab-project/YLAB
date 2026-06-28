function nodez = update_zcoord(zcoord, idz_coord, node)
%update_zcoord - 構造心Z座標を節点に反映する

nodez = node.z;
for i = 1:length(idz_coord)
  iz = idz_coord(i);
  istarget = node.idz == iz;
  nodez(istarget) = zcoord(iz) + node.dz(istarget);
end

return
end