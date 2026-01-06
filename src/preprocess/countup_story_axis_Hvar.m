function idvarH = countup_story_axis_Hvar(com)
% 共通定数
nmeg = com.nmeg;
% nnode = com.nnode;
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;

% 共通配列
idmeg2story = com.member.girder.idstory;
idmeg2var = com.member.girder.idvar;
idmeg2x = com.member.girder.idx;
idmeg2y = com.member.girder.idy;
idmeg2dir = com.member.girder.idir;
idme_exclusion = com.exclusion.girder_smooth.idme;
% idm2var = com.member.property.idvar;
% idm2n1 = com.member.property.idnode1;
% idm2n2 = com.member.property.idnode2;
% % idm2s = com.member.property.idsec;
% idn2s = com.node.idstory;
% mtype = com.member.property.type;

% 梁せいの上下接続を数え上げ
idvarHgx = zeros(nblx-1,nbly,nstory);
idvarHgy = zeros(nblx,nbly-1,nstory);
for ig=1:nmeg
  if any(ig==idme_exclusion)
    continue
  end
  idx = idmeg2x(ig,:);
  idy = idmeg2y(ig,:);
  ids = idmeg2story(ig,:);
  idir_ = idmeg2dir(ig);
  % idir==PRM.XY（45度梁）は両方向に登録
  if (idir_==PRM.X || idir_==PRM.XY)
    idvarHgx(idx(1):idx(2)-1,idy(1),ids) = idmeg2var(ig,1);
  end
  if (idir_==PRM.Y || idir_==PRM.XY)
    idvarHgy(idx(1),idy(1):idy(2)-1,ids) = idmeg2var(ig,1);
  end
end
% idvarHgx_ = idvarHgx;
% idvarHgy_ = idvarHgy;
idvarHgx = unique_var(idvarHgx);
idvarHgy = unique_var(idvarHgy);
idvarH = unique([idvarHgx; idvarHgy],'rows');

% すべて0の行を削除
idvarH(all(idvarH==0,2),:) = [];

% % すべて0の列を削除
% idvarH(:,all(idvarH==0,1)) = [];

% 層方向を行方向に
idvarH = idvarH';
return
  function idvar = unique_var(idvar)
    idvar = reshape(idvar,[],nstory);
    idvar = unique(idvar,'rows');
    % n = size(idvar,1);
    % istarget = true(1,n);
    % for i=1:n
    %   if all(idvar(i,:)==0)
    %     istarget(i) = false;
    %   end
    % end
    % idvar = idvar(istarget,:);
    % idvar(idvar==0) = [];
  end
end
