function [idngs, is_split_nominal, idmgs] = ...
  find_idnominal_girder_from_idxyz(...
  idx, idy, idz, nominal_girder, member_girder)
%find_idnominal_girder_from_idxyz - 名目梁検索と分割梁判定
n = size(idx, 1);

% 個別梁検索（1回のみ）
idmgs = find_idgirder_from_idxyz(...
  idx, idy, idz, member_girder);

% 逆マッピングで名目梁番号を取得
idmg1 = idmgs(:, 1);
valid = idmg1 > 0;
idngs = zeros(n, 1);
idngs(valid) = ...
  member_girder.idnominal(idmg1(valid), 1);

% is_split_nominal判定
is_split_nominal = false(n, 1);
vn = valid & idngs > 0;
ncols = sum(...
  nominal_girder.idmeg(idngs(vn), :) > 0, 2);
is_split_nominal(vn) = ...
  ~nominal_girder.isthrough(idngs(vn)) ...
  & ncols > 1;

return
end
