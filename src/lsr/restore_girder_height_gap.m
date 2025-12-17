function xlist = restore_girder_height_gap(xlist0, secdim0, secmgr, options)

% 計算の準備
[nlist0, nx] = size(xlist0);
xcell = cell(nlist0,1);

% 梁せい差の解消
if (nlist0==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
if do_parallel
  parfor i=1:nlist0
    xcell{i} = restore_individual(xlist0(i,:), secdim0(:,:,i), secmgr, options);
  end
else
  for i=1:nlist0
    xcell{i} = restore_individual(xlist0(i,:), secdim0(:,:,i), secmgr, options);
  end
end

% 結果の整理
nlist = 0;
xlist = zeros(1000,nx);
for i=1:nlist0
  ne = size(xcell{i},1);
  xlist(nlist+1:nlist+ne,:) = xcell{i};
  nlist = nlist+ne;
end
xlist = xlist(1:nlist,:);
xlist = unique(xlist,'rows','stable');
end

%--------------------------------------------------------------------------
function xlist = restore_individual(xvar, secdim, secmgr, options)

% 準備
xlist = [];
ishgv = options.coptions.consider_girder_height_gap_var;
ishgs = options.coptions.consider_girder_height_gap_section;

% 梁段差の対象断面がなければ終了
if ~ishgv&&~ishgs
  return
end
if ishgs
  ishgv = false;
end
if ishgv
  idHgap2v = secmgr.idHgap2var;
  conhgapvar = calc_girder_height_gap_var(xvar, idHgap2v, options);
else
  idHgap2v = [];
  conhgapvar = [];
end
if ishgs
  idHgap2s = secmgr.idHgap2sec;
  conhgapsec = calc_girder_height_gap_section(secdim, idHgap2s, options);
  idHgap2sv = [secmgr.idsec2var(idHgap2s(:,1),1) ...
    secmgr.idsec2var(idHgap2s(:,2),1)];
else
  idHgap2sv = [];
  conhgapsec = [];
end
idHgap2v = [idHgap2v; idHgap2sv];
conhgap = [conhgapvar; conhgapsec];
if all(conhgap<=options.tau)
  return
end

% 準備
% Hnset = unique(secmgr.Hnominal);
reqHgap = options.reqHgap;
tolHgap = options.tolHgap;
tau = options.tau;

% 初期化
nx = size(xvar,2);
maxgap = 4; % とりあえず
ngap = size(idHgap2v,1);
xcell = cell(ngap,1);
for ig = 1:ngap
  if conhgap(ig)<=tau
    % 許容な組み合わせなのでスキップ
    continue
  end
  idg2v = idHgap2v(ig,:);
  H0 = xvar(idg2v);
  nv = length(idg2v);

  % グリッド作成
  % TODO 変数ごとに作成する必要あり
  Hnset = nan(nv,100);
  for iv=1:nv
    Hn_ = unique(secmgr.getNominalValueSetofVar(idg2v(iv)));
    Hnset(iv,1:length(Hn_)) = Hn_;
  end
  Hnmin = min(Hnset,[],2)';
  Hnmax = max(Hnset,[],2)';
  Hu = min([H0+50*maxgap; Hnmax]); 
  Hl = max([H0-50*maxgap; Hnmin]); 
  switch nv
    case 2
      [g1, g2] = meshgrid(...
        Hnset(1,Hl(1)<=Hnset(1,:)&Hnset(1,:)<=Hu(1)), ...
        Hnset(2,Hl(2)<=Hnset(2,:)&Hnset(2,:)<=Hu(2)));
      Hgrid = [reshape(g1,[],1) reshape(g2,[],1)];
    otherwise
      warning('2種類以上の梁段差は考慮していません')
      xlist = xvar;
      return
  end
  ngrid = size(Hgrid,1);
  Hgap = zeros(ngrid,1);
  for igg=1:ngrid
    Hgap_ = abs(pdist(Hgrid(igg,:)'));
    Hgap_ = reshape(Hgap_',[],1);
    Hgap_(Hgap_<=tolHgap) = reqHgap;
    Hgap(igg) = min(Hgap_);
  end
  Hgrid = Hgrid(Hgap==reqHgap,:);
      
  % 距離計算
  % distance = pdist2(H0, Hgrid, 'fastsquaredeuclidean', 'Smallest', 1);
  distance = pdist2(H0, Hgrid, 'chebychev', 'Smallest', 1)';
  distance(distance<1) = inf;

  % 最小距離の候補解を追加
  % is_candidate = (distance<=min(distance)+10);
  is_candidate = (distance<=min(distance)+60);
  Hsol = Hgrid(is_candidate,:);
  xsol = repmat(xvar,size(Hsol,1),1);
  for is=1:size(Hsol,1)
    xsol(is,idg2v) = Hsol(is,:);
  end
  xcell{ig} = xsol;
end

% 結果の整理
nlist = 0;
for ig = 1:ngap
  ne = size(xcell{ig},1);
  nlist = nlist+ne;
end

ilist = 1;
xlist = zeros(nlist+1,nx);
xlist(1,:) = xvar;
for ig=1:ngap
  ne = size(xcell{ig},1);
  xlist(ilist+1:ilist+ne,:) = xcell{ig};
  ilist = ilist+ne;
end

return
end
