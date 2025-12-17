function isvalid = deprecated_getValidSectionOfSlist(secmgr, idslist, idphase)
% deprecated_getValidSectionOfSlist 有効断面リストを取得（非推奨）
%
% この関数は非推奨です。代わりに新しいAPIを使用してください：
%   secmgr.constraintValidator.getValidSectionList(idslist, idphase)

warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getValidSectionOfSlist は非推奨です。' ...
   '代わりに constraintValidator.getValidSectionList を使用してください。']);

if nargin == 2
  idphase = secmgr.idphase;
end

slist_type = secmgr.secList.section_type(idslist);
switch slist_type
  case PRM.WFS
    istarget = secmgr.secList.idphase{idslist}<=idphase;
    % isvalid = secmgr.secList.isValid{idslist};
    isvalid = secmgr.isValidSectionOfSlist_{idslist};
    % for i=1:size(isvalid,1)
    %   isvalid(i,:) = isvalid(i,:)&istarget;
    % end
    % istarget = istarget(secmgr.secList.isValid{idslist});
    isvalid = isvalid(:,istarget);
  case PRM.HSS
    isvalid = secmgr.isValidSectionOfSlist_{idslist};
  otherwise
    isvalid = secmgr.isValidSectionOfSlist_{idslist};
end

return
end