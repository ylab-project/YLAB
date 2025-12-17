function [xlist, isfailed] = restore_section_height(...
  xlist, st, stc, C, com, options)

% 共通配列
member = com.member;
Es = com.material.E(com.section.property.idmaterial);
Fs = com.material.F(com.section.property.idmaterial);
secmgr = com.secmgr;

% 対象変数のチェック
istarget = check_restoration_height(...
  xlist, st, stc, C, member, Es, Fs, secmgr, options);

% 計算の準備
[nlist, nx] = size(xlist);
xlist0 = xlist;
isfailed = false(nlist,nx);

% 復元操作
if (nlist==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
if do_parallel
  parfor id=1:nlist
    [xlist(id,:), isfailed(id,:)] = restore_each(...
      xlist0(id,:), istarget(id,:), secmgr, options);
  end
else
  for id=1:nlist
  [xlist(id,:), isfailed(id,:)] = restore_each(...
    xlist0(id,:), istarget(id,:), secmgr, options);
  end
end

% 重複の整理
[xlist, ia, ib] = unique(xlist,'rows','stable');
isfailed0 = isfailed;
isfailed = isfailed0(ia);
% istarget0 = istarget;
% istarget = istarget0(ia,:);
for i=1:nlist
  if isfailed0(i)
    isfailed(ib(i)) = true;
    % istarget(ib(i)) = istarget0(i,:);
  end
end
return
end

%--------------------------------------------------------------------------
function [xvar, isfailed] = restore_each(xvar, istarget, secmgr, options)
nx = length(xvar);
idvars = 1:nx;
idvars = idvars(istarget);
isfailed = false(1,nx);
vtype = secmgr.idvar2vtype;
for idvar=idvars
  switch vtype(idvar)
    case PRM.WFS_H
      [~, xup, ~] = secmgr.enumerateNeighborH(xvar, idvar, options);
      if ~isempty(xup)
        xvar(idvar) = xup(idvar);
      else
        isfailed(idvar) = true;
      end
    case PRM.WFS_TF
      [~, ~, xdw] = secmgr.enumerateNeighborTf(xvar, idvar, options);
      if ~isempty(xdw)
        xvar(idvar) = xdw(idvar);
      else
        isfailed(idvar) = true;
      end
  end
end
return
end

