function member_girder = countup_girder_stiffening(com)

% 共通配列
% member_column = com.member.column;
member_girder = com.member.girder;
member_property = com.member.property;

% 補剛数（均等）
member_girder.Lb(isnan(member_girder.Lb)) = ...
  member_property.lm(isnan(member_girder.Lb));
nstiff = member_property.lm(member_girder.idme)./member_girder.Lb;
% nstiff(isnan(nstiff)) = 1;

% 直接指定
nmeg = size(member_girder,1);
for ig=1:nmeg
end

member_girder.nstiff = nstiff;
end
