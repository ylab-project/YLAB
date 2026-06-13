function [idmegFace, idsecFace] = filter_column_face_list( ...
  idmegFace, idsecFace, targetDir, offAxis, tol, girderDir)
%filter_column_face_list - 方向矛盾のある梁IDと断面IDを同期除外

maskValid = idmegFace > 0;
idmegValid = idmegFace(maskValid);

maskRemove = false(size(idmegFace));
isRemove = girderDir(idmegValid) == targetDir ...
  & abs(offAxis(idmegValid)) > tol;
maskRemove(maskValid) = isRemove;

idmegFace(maskRemove) = 0;
idsecFace(maskRemove) = 0;

return
end
