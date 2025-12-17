function xlist = restore_column_diameter_gap(...
  xlist0, secdim0, Dgap, secmgr, options)

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
    xcell{i} = restore_individual(...
      xlist0(i,:), secdim0(:,:,i), Dgap, secmgr, options);
  end
else
  for i=1:nlist0
    xcell{i} = restore_individual(...
      xlist0(i,:), secdim0(:,:,i), Dgap, secmgr, options);
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
function xlist = restore_individual(xvar, secdim, Dgap, secmgr, options)

% 準備
xlist = [];
iscdg = options.coptions.consider_column_diameter_gap;

% 梁段差の対象断面がなければ終了
if ~iscdg
  return
end
idDgap2var = Dgap.idvar;
[condgap, Dgapval] = calc_column_diameter_gap_var(xvar, idDgap2var, options);
if all(condgap<=options.tau)
  return
end

% 準備
idxyset = Dgap.idxy;
tolMaxDgap = options.tolMaxDgap;
tau = options.tau;

% 初期化
nx = size(xvar,2);
% maxgap = tolMaxDgap/50;
% ngap = size(idDgap2var,1);
[~, idu1, idu2] = unique(idxyset,'rows');
nxy = length(idu1);
xcell = cell(nxy,1);
lpopt = optimoptions('intlinprog' ...
  ...,'Algorithm', 'legacy' ...
  ,'Display', 'off' ...
  ,'MaxTime', 3 ...
  ... ,'OutputFcn', @customFcn ...
  );

% 通りごとに探索
for id = 1:nxy
  xInts = [];
  target = (idu2==id);
  maxDgapval = max(Dgapval(target));
  if maxDgapval<=tau && -tolMaxDgap-maxDgapval<=tau
    % 許容な組み合わせなのでスキップ
    continue
  end

  % 整数計画の準備
  idg2v = idDgap2var(target,:);
  idx2v = unique(idg2v);
  nv = length(idx2v);
  ngap_ = size(idg2v,1);
  idg2x = idg2v;
  for iv=1:nv
    idg2x(idg2v==idx2v(iv)) = iv;
  end
  D0 = xvar(idx2v);
  if any(mod(D0,50)~=0)
    continue
  end
  x0 = [D0(:)/50; 0];
  ub = [D0(:)/50; 0];
  lb = [D0(:)/50; 0];

  % 上下限値＝規格値ワンサイズアップ／ダウン
  for iv=1:nv
    [~, xup, xdw] = secmgr.enumerateNeighborD(xvar, idx2v(iv), options);
    if ~isempty(xup)
      ub(iv) = ceil(xup(idx2v(iv))/50);
    end
    if ~isempty(xdw)
      lb(iv) = floor(xdw(idx2v(iv))/50);
    end
  end

  % 係数行列
  f = [zeros(nv,1); 1];
  A = zeros(ngap_*2,nv+1);
  b = [zeros(ngap_,1); tolMaxDgap*ones(ngap_,1)/50];
  for i=1:ngap_
    A(i, idg2x(i,:)) = [1 -1];
    A(i+ngap_, idg2x(i,:)) = [-1 1];
  end
  A(:,nv+1) = -1;

  % 変数の設定
  s0 = max(max(A(:,1:nv)*x0(1:nv)-b),0);
  x0(nv+1) = s0;
  ub(nv+1) = s0;
  

  % 求解
  % vio = max([A*x0-b; lb-x0; x0-ub]);
  % if (vio>0)
  %   vio
  % end
  xsol = intlinprog(f,1:nv+1,A,b,[],[],lb,ub,x0,lpopt);
  xvarsol = xvar;
  xvarsol(idx2v) = xsol(1:nv)*50;

  % 最小距離の候補解を追加
  % is_candidate = (distance<=min(distance)+10);
  % is_candidate = (distance<=min(distance)+60);
  % Hsol = Hgrid(is_candidate,:);
  % xsol = repmat(xvar,size(Hsol,1),1);
  % for is=1:size(Hsol,1)
  %   xsol(is,idg2v) = Hsol(is,:);
  % end
  xcell{id} = xvarsol;
end

% 結果の整理^
nlist = 0;
for id = 1:nxy
  ne = size(xcell{id},1);
  nlist = nlist+ne;
end

ilist = 1;
xlist = zeros(nlist+1,nx);
xlist(1,:) = xvar;
for id = 1:nxy
  ne = size(xcell{id},1);
  xlist(ilist+1:ilist+ne,:) = xcell{id};
  ilist = ilist+ne;
end

return
  function stop = customFcn(x,optimValues,state)
    if ~isempty(x)
      xInts = [xInts, x(:)];
    end
    stop = false;
  end
end
