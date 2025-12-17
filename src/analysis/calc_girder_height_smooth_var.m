function [conhsmoothvar, Dmat, varH] = calc_girder_height_smooth_var(...
  xvar, idstory2varH, options)

% 計算の準備
% [nstory, naxis] = size(idstory2varH);
% idvarH = reshape(idstory2varH(idstory2varH>0),1,[]);
% idvarH = unique(idvarH);
% varH = xvar(idvarH);

% % 層・通りごとの梁せい
% varH = zeros(nstory,naxis);
% varH(idstory2varH>0) = xvar(idstory2varH(idstory2varH>0));
% varH(all(varH==0,2),:) = [];

% switch options.coptions.alfa_girder_height_smooth_var
%   case PRM.GIRDER_HEIGHT_SMOOTH_MAX
%     varH = max(varH,2);
%   case PRM.GIRDER_HEIGHT_SMOOTH_AXIS
% end

[Dmat, varH] = Hdiff_matrix(xvar, idstory2varH, options);

% istarget = true(1,nstory);
% for is=1:nstory
%   for ia=1:naxis
%     idvar = idstory2varH(is,idstory2varH(is,ia)>0);
%     if isempty(idvar)
%       istarget(is) = false;
%       continue
%     end
%     H(is) = max(xvar(idvar));
%   end
% end
% H = H(istarget);

% % 1階差分行列
% [nH, mH] = size(H);
% D1_ = zeros(nH-1,nH);
% for is=1:nH-1
%   D1_(is,is:is+1) = [-1 1];
% end
% 
% % 1階差分全体行列
% D1 = zeros((nH-1)*mH,nH*mH);
% for ia=1:mH
%   irow = (ia-1)*(nH-1);
%   icol = (ia-1)*nH;
%   D1(irow+1:irow+nH-1,icol+1:icol+nH) = D1_;
% end

% % 2階差分
% D2 = zeros(nstory-2,nstory);
% for is=1:nstory-2
%   D2(is,is:is+2) = [-1 2 -1];
% end

% conhsmoothvar = D1*reshape(varH,[],1)/50;
conhsmoothvar = Dmat*varH(:)/50;
return
end

% % 梁せい差の計算
% H = zeros(nstory,naxis);
% istarget = true(1,nstory);
% for is=1:nstory
%   idvar = idstory2varH(is,idstory2varH(is,:)>0);
%   if isempty(idvar)
%     istarget(is) = false;
%     continue
%   end
%   H(is) = max(xvar(idvar));
% end
% H = H(istarget);
% 
% % 1階差分
% nH = length(H);
% D1 = zeros(nH-1,nH);
% for is=1:nH-1
%   D1(is,is:is+1) = [-1 1];
% end
% 
% % % 2階差分
% % D2 = zeros(nstory-2,nstory);
% % for is=1:nstory-2
% %   D2(is,is:is+2) = [-1 2 -1];
% % end
% 
% conhsmoothvar  = D1*H/50;
