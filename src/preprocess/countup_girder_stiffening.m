function member_girder = countup_girder_stiffening(com, lm)
%countup_girder_stiffening - 梁の補剛数を算定する

% 共通配列
member_girder = com.member.girder;
idme = member_girder.idme;
lm_girder = lm(idme);

% 補剛数（均等）
member_girder.Lb(isnan(member_girder.Lb)) = ...
  lm_girder(isnan(member_girder.Lb));
nstiff = lm_girder ./ member_girder.Lb;
% nstiff(isnan(nstiff)) = 1;

member_girder.nstiff = nstiff;

return
end
