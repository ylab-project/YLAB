function xlist = restore_girder_height_gap_ip(...
  xlist0, idvlist, secdim0, secmgr, options)

% 共通処理
% nlist0 = size(xlist0,1);
igapreq = ceil(options.reqHgap/50);
ishgv = options.coptions.consider_girder_height_gap_var;
ishgs = options.coptions.consider_girder_height_gap_section;
xlist = [];

% 梁段差の対象断面がなければ終了
if ~ishgv&&~ishgs
  return
end

% 梁段差対象変数の検索
if ishgs
  ishgv = false;
end
if ishgv
  idgap2v = secmgr.idHgap2var;
  % conhgapvar = calc_girder_height_gap_var(xvar, idHgap2v, options);
else
  idgap2v = [];
  conhgapvar = [];
end
if ishgs
  idgap2s = secmgr.idHgap2sec;
  % conhgapsec = calc_girder_height_gap_section(secdim, idHgap2s, options);
  idgap2s = [secmgr.idsec2var(idgap2s(:,1),1) ...
    secmgr.idsec2var(idgap2s(:,2),1)];
else
  idgap2s = [];
  % conhgapsec = [];
end
idgap2v = [idgap2v; idgap2s];
% conhgap = [conhgapvar; conhgapsec];
% if all(conhgap<=options.tau)
% return
% end

% 配列の初期化
[nlist0, nx] = size(xlist0);

% Hと整数変数の関係
[idi2Hvar, idH2ivar, Dimat] = find_idgapvar(idgap2v, nx);


% 計算の準備
ilb = ceil(secmgr.lb(idi2Hvar)/50);
iub = ceil(secmgr.ub(idi2Hvar)/50);
[ilist, xlist, idvarlist] = extract_ilist(xlist0, idvlist);
ilist0 = ilist;

% 梁せい差の解消
if (size(ilist,1)==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
if do_parallel
  parfor i=1:size(ilist,1)
    ilist(i,:) = restore_individual(...
      ilist(i,:), idvarlist(i,:), ilb, iub, Dimat, igapreq);
  end
else
  for i=1:size(ilist,1)
    ilist(i,:) = restore_individual(...
      ilist(i,:), idvarlist(i,:), ilb, iub, Dimat, igapreq);
  end
end

% 結果の整理
xlist = insert_ilist(xlist, ilist);
xlist = unique(xlist,'rows','stable');

return

%--------------------------------------------------------------------------
  function [ilist, xlist, idvarlist] = extract_ilist(xlist, idvlist)
    % 重複のない整数変数の組合せ
    mivar = length(idi2Hvar);
    nlist_ = size(xlist,1);
    ilist_ = zeros(nlist_, mivar);
    for i_=1:nlist_
      ilist_(i_,:) = ceil(xlist(i_,idi2Hvar)/50);
    end
    [ilist, idi2x] = unique(ilist_, 'rows');
    xlist = xlist(idi2x,:);

    % 増分方向
    idvarlist = zeros(nlist_,1);
    idvarlist(idvlist~=0) = idH2ivar(abs(idvlist(idvlist~=0)));
    idvarlist = idvarlist.*sign(idvlist);
    idvarlist = idvarlist(idi2x);

    % 復元対象か判定
    igap = Dimat*ilist';
    istarget = any(igap~=0 & abs(igap)<igapreq);
    ilist(~istarget,:) = [];
    xlist(~istarget,:) = [];
    idvarlist(~istarget) = [];
    return
  end
%--------------------------------------------------------------------------
  function xlist = insert_ilist(xlist, ilist)
    nlist_ = size(ilist,1);
    for i_=1:nlist_
      xlist(i_,idi2Hvar) = ilist(i_,:)*50;
    end
    return
  end
end



%--------------------------------------------------------------------------
function [idi2Hvar, idH2ivar, Dimat] = find_idgapvar(idgap2v, nx)
% 段差計算のHの組の検索
% idgap2v(isnan(idgap2v)) = 0;
% idgap2v = unique(idgap2v,'rows');
% [n,m] = size(idgap2v);
% ick = nchoosek(1:m,2);
% nck = size(ick,1);
% idgapHvar = zeros(n*m,2);
% for i=1:n
%   for j=1:nck
%     idgapHvar((i-1)*nck+j,:) = idgap2v(i,ick(j,:));
%   end
% end
% idgapHvar(any(idgapHvar==0,2),:) = [];
% idgapHvar = unique(idgapHvar,'rows');
idgapHvar = idgap2v;
idi2Hvar = unique(idgapHvar)';

% Hと整数変数のid変換
idH2ivar = zeros(1,nx);
mDi = length(idi2Hvar);
idH2ivar(idi2Hvar) = 1:mDi;
idgapivar = idH2ivar(idgapHvar);

% 差分行列の作成
nDi = size(idgapHvar,1);
Dimat = zeros(nDi,mDi);
for i=1:nDi
  Dimat(i,idgapivar(i,:)) = [1 -1];
end
return
end

%--------------------------------------------------------------------------
function x = restore_individual(x0, idvar, xlb, xub, Dmat, dreq)

% 計算の準備
[m,n] = size(Dmat);
x0 = x0(:);

% x変化量の上限
dmax = 4;

% 緩和ペナルティ
M = 1000;

% 違反量計算
d0 = Dmat*x0;
dimax = max(abs(d0),dmax);

% --- 整数変数 ---
xpub = max(xub-x0,0);
xpub(xpub>dmax) = dmax;
xnub = max(-xlb+x0,0);
xnub(xnub>dmax) = dmax;

% 初期値
xp = zeros(n,1);
xn = zeros(n,1);

% --- 緩和変数 ---
rpub = zeros(m,1);
rnub = zeros(m,1);
r1 = d0;
r2 = dreq-d0;
iddd = 0<d0 & d0<dreq;
rpub(iddd&r1<=r2) = r1(iddd&r1<=r2);
rnub(iddd&r1>=r2) = r2(iddd&r1>=r2);
r1 = dreq+d0;
r2 = -d0;
iddd = 0>d0 & d0>-dreq;
rpub(iddd&r1<=r2) = r1(iddd&r1<=r2);
rnub(iddd&r1>=r2) = r2(iddd&r1>=r2);

% 初期値
rp = rpub;
rn = rnub;

% --- 制約変数 ---
s0 = zeros(m,1);
sp = zeros(m,1);
sn = zeros(m,1);
s0(-rn<=d0&d0<=rp) = 1;
sp(dreq-rn<=d0) = 1;
sn(d0<=-dreq+rp) = 1;

% --- 係数行列 ---
On = zeros(m,n);
Om = zeros(m,m);
Im = eye(m);
A = [...
  Dmat -Dmat Om -diag(dimax) dreq*Im -Im Om; ...
  -Dmat Dmat Om dreq*Im -diag(dimax) Om -Im ; ...
  ];
b = [-d0; d0];
Aeq = [On On Im Im Im Om Om];
beq = ones(m,1);
if idvar>0
  aaa = zeros(1,size(Aeq,2));
  aaa(abs(idvar)+n) = 1;
  Aeq = [Aeq; aaa];
  beq = [beq; 0];
elseif idvar<0
  aaa = zeros(1,size(Aeq,2));
  aaa(abs(idvar)) = 1;
  Aeq = [Aeq; aaa];
  beq = [beq; 0];
end

% --- 目的関数 ---
en = ones(n,1);
em = ones(m,1);
on = zeros(n,1);
om = zeros(m,1);
f = [en; en; om; om; om; M*em; M*em;];

% --- 求解 ---
y0 = [xp; xn; s0; sp; sn; rp; rn];
lb = [on; on; om; om; om; om; om];
ub = [xpub; xnub; em; em; em; rpub; rnub];
ny = length(y0);
% check1 = A*y-b;
% check2 = Aeq*y-beq;
opts = optimoptions("intlinprog","Display","off");
[y,~,exitflag] = intlinprog(f,1:ny,A,b,Aeq,beq,lb,ub,y0,opts);
xp = y(1:n);
xn = y(n+1:2*n);
x = x0+xp-xn;
return
end
