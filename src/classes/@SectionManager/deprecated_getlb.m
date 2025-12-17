function lb = deprecated_getlb(secmgr, idslist)
% deprecated_getlb 下限値取得（非推奨）
%
% この関数は非推奨です。代わりにconstraintValidator.getLowerBoundsを
% 使用してください。
%
% See also: getLowerBounds

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_getlb は非推奨です。' ...
   '代わりに constraintValidator.getLowerBounds を使用してください。']);

lb = nan(1,secmgr.nxvar);
vtypeset = PRM.VTYPE_SET_BOUNDS();
for vtype=vtypeset
  istarget = secmgr.isVarofSlist(:,idslist)&secmgr.idvar2vtype==vtype;
  if all(~istarget)
    % 対象外スキップ
    continue
  end
  switch vtype
    case PRM.WFS_H
      val = secmgr.deprecated_getHnominal(idslist);
    case PRM.WFS_B
      val = secmgr.deprecated_getBnominal(idslist);
    case PRM.WFS_TW
      % val = secmgr.getTfst(idslist);
      val = secmgr.deprecated_getTwst(idslist);
    case PRM.WFS_TF
      % val = secmgr.getTwst(idslist);
      val = secmgr.deprecated_getTfst(idslist);
    case PRM.HSS_D
      val = secmgr.deprecated_getDst(idslist);
    case PRM.HSS_T
      val = secmgr.deprecated_getTst(idslist);
    case PRM.BRB_V1
      val = secmgr.deprecated_getBrb1st(idslist);
    case PRM.BRB_V2
      val = secmgr.deprecated_getBrb2st(idslist);
  end
  if ~isempty(val)
    lb(istarget) = min(val);
  end
end

return
end