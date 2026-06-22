function [idmegFace, idsecFace] = filter_column_face_list( ...
  idmegFace, idsecFace, is_target_dir)
%filter_column_face_list - 方向対象外の梁IDと断面IDを同期除外

mask_valid = idmegFace > 0;
idmeg_valid = idmegFace(mask_valid);

mask_remove = false(size(idmegFace));
is_remove = ~is_target_dir(idmeg_valid);
mask_remove(mask_valid) = is_remove;

idmegFace(mask_remove) = 0;
idsecFace(mask_remove) = 0;

return
end
