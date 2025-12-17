function [xlist, isfailed, istarget] = restore_section_thickness(...
  xlist, st, stc, C, com, options)

% 共通配列
member = com.member;
% Es = com.material.E(com.section.property.idmaterial);
% Fs = com.material.F(com.section.property.idmaterial);
matE = com.material.E;
matF = com.material.F;
secmgr = com.secmgr;

% 対象変数のチェック
[xlist, istarget] = check_restoration_thickness(...
  xlist, st, stc, C, member, matE, matF, secmgr, options);

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
    [xlist(id,:), isfailed(id,:)] = restore_thickness_individual(...
      xlist0(id,:), istarget(id,:), secmgr, options);
  end
else
  for id=1:nlist
  [xlist(id,:), isfailed(id,:)] = restore_thickness_individual(...
    xlist0(id,:), istarget(id,:), secmgr, options);
  end
end

% 重複の整理
[xlist, ia, ib] = unique(xlist,'rows','stable');
isfailed0 = isfailed;
isfailed = isfailed0(ia);
istarget0 = istarget;
istarget = istarget0(ia,:);
for i=1:nlist
  if isfailed0(i)
    isfailed(ib(i)) = true;
    istarget(ib(i)) = istarget0(i,:);
  end
end
return
end

%--------------------------------------------------------------------------
function [xvar, isfailed] = restore_thickness_individual( ...
  xvar, istarget, secmgr, options)
nx = length(xvar);
idvars = 1:nx;
idvars = idvars(istarget);
isfailed = false(1,nx);
vtype = secmgr.idvar2vtype;
for idvar=idvars
  switch vtype(idvar)
    % case PRM.WFS_H
    %   [~, xup, ~] = secmgr.enumerateNeighborH(xvar, idvar, options);
    %   if ~isempty(xup)
    %     xvar(idvar) = xup(idvar);
    %   else
    %     isfailed(idvar) = true;
    %   end
    case PRM.WFS_TW
      [~, xup, ~, idvartarget] = secmgr.enumerateNeighborTw(xvar, idvar, options);
      if ~isempty(xup)
        if size(idvartarget,1)==1
          xvar(idvartarget(3:4)) = xup(idvartarget(3:4));
        else
          xvar(idvar) = xup(idvar);
        end
      else
        isfailed(idvar) = true;
      end
    case PRM.WFS_TF
      [~, xup, ~, idvartarget] = secmgr.enumerateNeighborTf(xvar, idvar, options);
      if ~isempty(xup)
        if size(idvartarget,1)==1
          xvar(idvartarget(3:4)) = xup(idvartarget(3:4));
        else
          xvar(idvar) = xup(idvar);
        end
      else
        isfailed(idvar) = true;
      end
    case PRM.HSS_T
      [~, xup] = secmgr.enumerateNeighborT(xvar, idvar, options);
      if ~isempty(xup)
        isfailed(idvar) = true;
      end
  end
end
return
end

% %--------------------------------------------------------------------------
% function xvar = restore_wtratio(xvar, conwtg, conwtc, secmgr, options)
%
% % 共通配列
% % idsc2v = secmgr.idsec2var(secmgr.idsec2stype==PRM.HSS,:);
% % idsg2v = secmgr.idsec2var(secmgr.idsec2stype==PRM.WFS,:);
% idsrep2stype = secmgr.idsrep2stype;
% idsrep2var = secmgr.idsrep2var;
% % secclist = secmgr.listcmat;
% % secglist = secmgr.listgmat;
% % sechss = secdim(secmgr.idsec2stype==PRM.HSS,:);
% % secwfs = secdim(secmgr.idsec2stype==PRM.WFS,:);
%
% % 計算の準備
% % nsecc = length(idsc2v);
% % nsecg = length(idsg2v);
% xvar0 = xvar;
%
% % 違反制約のチェック
% isviot = conwtc>0;
% conwtg = reshape(conwtg,[],2);
% isviotw = conwtg(:,2)>0;
% isviotf = conwtg(:,1)>0;
% if all([~isviot; ~isviotw; ~isviotf])
%   return
% end
%
% % 関係変数のチェック
% idupt = idsrep2var(idsrep2stype==PRM.HSS,2);
% idupt = unique(idupt(isviot))';
% iduptw = idsrep2var(idsrep2stype==PRM.WFS,3);
% iduptw = unique(iduptw(isviotw))';
% iduptf = idsrep2var(idsrep2stype==PRM.WFS,4);
% iduptf = unique(iduptf(isviotf))';
%
% % 2023.8.9 以降を修正する
% % warning('要修正')
%
% % H形鋼の幅厚比制約違反からの復元操作
% for idvar=iduptw
%   [~, xup] = secmgr.enumerateNeighborTw(xvar, idvar, options);
%   if ~isempty(xup)
%     xvar(idvar) = xup(idvar);
%   end
% end
% for idvar=iduptf
%   [~, xup] = secmgr.enumerateNeighborTf(xvar, idvar, options);
%   if ~isempty(xup)
%     xvar(idvar) = xup(idvar);
%   end
% end
%
% % 角形鋼管の幅厚比制約違反からの復元操作
% for idvar=idupt
%   [~, xup] = secmgr.enumerateNeighborT(xvar, idvar, options);
%   if ~isempty(xup)
%     xvar(idvar) = xup(idvar);
%   end
% end
%
% % % H形鋼の幅厚比制約違反からの復元操作
% % for ig=1:nsecg
% %   if isviotw(ig)
% %     upsec = secmgr.findUpDownWfsThick(secwfs(ig,1:4), 'tw', secglist, options);
% %     if ~isempty(upsec)
% %       xvar(idsg2v(ig,3)) = upsec(1,3);
% %     end
% %   end
% %   if isviotf(ig)
% %     upsec = secmgr.findUpDownWfsThick(secwfs(ig,1:4), 'tf', secglist, options);
% %     if ~isempty(upsec)
% %       xvar(idsg2v(ig,4)) = upsec(1,4);
% %     end
% %   end
% % end
%
% % % 角形鋼管の幅厚比制約違反からの復元操作
% % for ic=1:nsecc
% %   if isviot(ic)
% %     upsec = secmgr.findUpDownHssThick(sechss(ic,1:2), secclist, options);
% %     if ~isempty(upsec)
% %       xvar(idsc2v(ic,2)) = upsec(1,2);
% %     end
% %   end
% % end
% return
% end
%
% %--------------------------------------------------------------------------
% function xvar = restore_slenderness_ratio(xvar, consr, secmgr, options)
%
% % 共通配列
% idmeg2v = secmgr.idme2var(secmgr.idme2stype==PRM.WFS,:);
% % secglist = secmgr.listgmat;
% % secwfs = secdim(secmgr.idsec2stype==PRM.WFS,:);
%
% % 計算の準備
% % nsecg = length(idmeg2v);
% xvar0 = xvar;
%
% % 違反制約のチェック
% isviotf = consr>0;
% if all(~isviotf)
%   return
% end
%
% % 関係変数のチェック
% iduptf = unique(idmeg2v(isviotf,4))';
%
% % 細長比制約違反からの復元操作
% for idvar=iduptf
%   [~, xup] = secmgr.enumerateNeighborTf(xvar, idvar, options);
%   if ~isempty(xup)
%     xvar(idvar) = xup(idvar);
%   end
% end
% return
% end
%
% %--------------------------------------------------------------------------
% function xvar = restore_stress_ratio(...
%   xvar, gr, gs, cr, cs, gapj, secmgr, options)
%
% % 共通配列
% % idsc2v = secmgr.idsec2var(secmgr.stype==PRM.HSS,:);
% % idsg2v = secmgr.idsec2var(secmgr.stype==PRM.WFS,:);
% idmec2v = secmgr.idme2var(secmgr.idme2stype==PRM.HSS,:);
% idmeg2v = secmgr.idme2var(secmgr.idme2stype==PRM.WFS,:);
% % secclist = secmgr.listcmat;
% % secglist = secmgr.listgmat;
% % secwfs = secdim(secmgr.stype==PRM.WFS,:);
% % sechss = secdim(secmgr.stype==PRM.HSS,:);
%
%
% % 計算の準備
% % nsecc = length(idsc2v);
% % nsecg = length(idsg2v);
% xvar0 = xvar;
% tol = options.tolRestoreSr;
% immm = 1:size(idmeg2v,1);
%
% % H形鋼のせん断許容応力度比制約違反からの復元操作
% idviotw = unique(idmeg2v(gs>tol,3))';
% for idvar=idviotw
%   [~, xup] = secmgr.enumerateNeighborTw(xvar, idvar, options);
%   if ~isempty(xup)
%     xvar = xup;
%   end
% end
%
% % H形鋼の曲げ許容応力度比制約違反からの復元操作
% idviotf = unique(idmeg2v(gr>tol,4))';
% for idvar=idviotf
%   % isRestored = false;
%   % im = immm(idmeg2v(:,4)==ivtf&gr>tol);
%   [~, xup] = secmgr.enumerateNeighborTf(xvar, idvar, options);
%   if ~isempty(xup)
%     xvar = xup;
%   end
% end
%
% % if (~isRestored)
% %   ivB = unique(idmeg2v(im,2));
% %   jddd = randperm(length(ivB));
% %   for jd = jddd
% %     [~, xup] = secmgr.enumerateNeighborB(xvar, ivB(jd), options);
% %     if ~isempty(xup)
% %       isRestored = true;
% %       xvar = xup;
% %       break
% %     end
% %   end
% % end
%
% % if (~isRestored)
% %   % fprintf('gr(%d):empty B\n',ivB);
% %   ivH = unique(idmeg2v(im,1));
% %   jddd = randperm(length(ivH));
% %   for jd = jddd
% %     [~, xvarnew] = secmgr.enumerateNeighborH(xvar, ivH(jd), gapj, options);
% %     if ~isempty(xvarnew)
% %       isRestored = true;
% %       xvar = xvarnew;
% %       break
% %     end
% %   end
% % end
%
% % if (~isRestored)
% % fprintf('gr(%d):empty H\n',ivH);
% % end
% % end
%
% % 角形鋼管の許容応力度比制約違反からの復元操作
% idviot = unique(idmec2v(cr>=tol|cs>tol,2))';
% for idvar=idviot
%   [~, xup] = secmgr.enumerateNeighborT(xvar, idvar, options);
%   if ~isempty(xup)
%     xvar = xup;
%   end
% end
%
% return
% end
