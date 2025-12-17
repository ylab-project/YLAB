function ub = deprecated_getub(secmgr, id)
% deprecated_getub 上限値取得（非推奨）
%
% この関数は非推奨です。代わりにconstraintValidator.getUpperBoundsを
% 使用してください。
%
% See also: getUpperBounds

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getub は非推奨です。' ...
   '代わりに constraintValidator.getUpperBounds を使用してください。']);

ub = nan(1,secmgr.nxvar);
vtypeset = PRM.VTYPE_SET_BOUNDS();
for iv=vtypeset
  istarget = secmgr.isVarofSlist(:,id)&secmgr.idvar2vtype==iv;
  if all(~istarget)
    % 対象外スキップ
    continue
  end
  switch iv
    case PRM.WFS_H
      val = secmgr.deprecated_getHnominal(id);
    case PRM.WFS_B
      val = secmgr.deprecated_getBnominal(id);
    case PRM.WFS_TW
      % val = secmgr.getTfst(id);
      val = secmgr.deprecated_getTwst(id); % 修正250302
    case PRM.WFS_TF
      % val = secmgr.getTwst(id);
      val = secmgr.deprecated_getTfst(id); % 修正250302
    case PRM.HSS_D
      val = secmgr.deprecated_getDst(id);
    case PRM.HSS_T
      val = secmgr.deprecated_getTst(id);
    case PRM.BRB_V1
      val = secmgr.deprecated_getBrb1st(id);
    case PRM.BRB_V2
      val = secmgr.deprecated_getBrb2st(id);
  end
  if ~isempty(val)
    ub(istarget) = max(val);
  end
end

return
end