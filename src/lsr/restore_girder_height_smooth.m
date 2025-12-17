function xlist = restore_girder_height_smooth(...
  xlist0, idvlist, secdim0, secmgr, idstory2varH, options)

% 計算の準備
[nlist0, nx] = size(xlist0);
xcell = cell(nlist0,1);

% 梁せい分布の平滑化
if (nlist0==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
if do_parallel
  parfor i=1:nlist0
    xcell{i} = restore_individual(...
      xlist0(i,:), idvlist(i), secdim0(:,:,i), secmgr, idstory2varH, options);
  end
else
  for i=1:nlist0
    xcell{i} = restore_individual(...
      xlist0(i,:), idvlist(i), secdim0(:,:,i), secmgr, idstory2varH, options);
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
function xvar = restore_individual(...
  xvar0, idvar, secdim, secmgr, idstory2varH, options)

% 準備
% [nstory, mH] = size(idstory2varH);
xvar = [];
consider_hsvar = options.coptions.consider_girder_height_smooth_var;

% 梁の対象断面がなければ終了
if ~consider_hsvar
  return
end
conhsvar = calc_girder_height_smooth_var(...
  xvar0, idstory2varH, options);
if all(conhsvar<=options.tau)
  return
end

% 準備
% Hnset = unique(secmgr.Hnominal);
% reqHgap = options.reqHgap;
% tolHgap = options.tolHgap;
% tau = options.tau;
idvarH = reshape(idstory2varH(idstory2varH>0),1,[]);
idvarH = unique(idvarH);
varH0 = xvar0(idvarH);
nv = length(idvarH);

% 整数計画の準備
x0 = round(varH0(:)/50);
xu = x0; xl = x0;

% 上下限値＝規格値ワンサイズアップ／ダウン
dH = 150;
for iv=1:nv
  if iv==abs(idvar)
    % 動かさない変数
    continue
  end
  [~, xup, xdw] = secmgr.enumerateNeighborH(xvar0, idvarH(iv), options, dH);
  if ~isempty(xup)
    xu(iv) = round(xup(end,idvarH(iv))/50);
  end
  if ~isempty(xdw)
    xl(iv) = round(xdw(end,idvarH(iv))/50);
  end
end

% 計算準備
type_hsvar = options.coptions.alfa_girder_height_smooth_var;
[Dmat, H, idtstory2H, Hmax, idtstory2Hmax] = ...
  Hdiff_matrix(xvar0, idstory2varH, options);
[ntstory, naxis] = size(idtstory2H);

% --- 係数行列 ---
% 目的関数
ns = size(Dmat,1);
N = 3*nv+ns;
f = [zeros(1,nv) ones(1,nv) ones(1,nv) 10*ones(1,ns)]';

% 同一層内
switch type_hsvar
  case PRM.GIRDER_HEIGHT_SMOOTH_MAX
    nnn = nnz(idtstory2H)-ntstory;
    A1mat = zeros(nnn,nv);
    irow = 0;
    for i=1:ntstory
      idHmax = idtstory2Hmax(i);
      idH = unique(idtstory2H(i,:));
      idH(idH==0) = [];
      idH(idH==idHmax) = [];
      for j=1:length(idH)
        irow = irow+1;
        A1mat(irow,[idHmax idH(j)]) = [-1 1];
      end
    end
  case PRM.GIRDER_HEIGHT_SMOOTH_AXIS
    A1mat = zeros(0,nv);
end

% 結合
A = [A1mat zeros(size(A1mat,1),nv*2+ns) 
  Dmat zeros(ns,nv*2) -eye(ns)];
nA = size(A,1);
b = zeros(nA,1);

% スラック変数
Aeq = zeros(nv,N);
beq = x0(1:nv);
for i=1:nv
  Aeq(i,[i i+nv i+nv*2]) = [1 -1 1];
end

% 変数の設定
s0 = Dmat*x0(1:nv);
s0(s0<0) = 0;
x00 = x0;
y0 = [x00; zeros(nv*2,1); s0];
lb = [xl; zeros(nv*2,1); zeros(ns,1)];
ub = [xu; x0-xl; xu-x0; s0];

% オプション設定
lpopt = optimoptions('intlinprog' ...
  ...,'Algorithm', 'legacy' ...
  ...,'Display', 'iter' ...
  ,'Display', 'off' ...
  ...,'MaxTime', 3 ...
  ... ,'OutputFcn', @customFcn ...
  );

% 求解
[ysol,fval,exitflag,output] = intlinprog(...
  f,numel(f),A,b,Aeq,beq,lb,ub,y0,lpopt);
Hsol = round(ysol(1:nv))*50;
xvar = xvar0;
xvar(idvarH) = Hsol;
return
end
