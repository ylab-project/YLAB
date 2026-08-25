function [end_member, face] = get_nominal_girder_end_members( ...
  idmeg, idmg2m, lf)
%get_nominal_girder_end_members - 名目梁の端部部材とフェイス長を取得
%
%   [end_member, face] = get_nominal_girder_end_members(idmeg,
%   idmg2m, lf) は、各名目梁の最初と最後のsub梁から端部部材番号と
%   対応するフェイス長を取得する。
%
%   入力引数:
%     idmeg  - 名目梁からsub梁への対応
%     idmg2m - 梁番号から部材番号への対応
%     lf     - フェイス長構造体
%
%   出力引数:
%     end_member - 名目梁のi端・j端部材番号 [nng x 2]
%     face       - 名目梁のi端・j端フェイス長 [nng x 2] (mm)

nng = size(idmeg, 1);
end_member = zeros(nng, 2);
face = zeros(nng, 2);
for ing = 1:nng
  igs = nonzeros(idmeg(ing, :));
  if isempty(igs)
    continue
  end
  end_girder = [igs(1), igs(end)];
  end_member(ing, :) = idmg2m(end_girder);
  face(ing, 1) = lf.girder(end_girder(1), 1);
  face(ing, 2) = lf.girder(end_girder(2), 2);
end

return
end
