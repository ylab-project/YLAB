function xlist = restore_girder_height_smooth(xlist0, idvlist, ...
  secmgr, height_smooth, isvar, options)
%restore_girder_height_smooth - 梁せい分布平滑化違反の復元
%
%   xlist = restore_girder_height_smooth(xlist0, idvlist, secmgr,
%     height_smooth, isvar, options) は、梁せい分布平滑化の違反を
%   整数計画で解消した変数値候補を生成する。直前に動かした変数と
%   固定変数は現在値にピン止めして動かさない。
%
%   入力引数:
%     xlist0        - 変数値の候補リスト [nlist×nx]
%     idvlist       - 直前に動かした変数のグローバルID（0=指定なし）
%     secmgr        - SectionManagerインスタンス
%     height_smooth - 平滑化の固定データ（idvarH等）
%     isvar         - 設計変数フラグ [nx×1]（偽=固定）
%     options       - 共通オプション
%
%   出力引数:
%     xlist - 復元後の変数値候補

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
    xcell{i} = restore_individual(xlist0(i,:), idvlist(i), secmgr, ...
      height_smooth, isvar, options);
  end
else
  for i=1:nlist0
    xcell{i} = restore_individual(xlist0(i,:), idvlist(i), secmgr, ...
      height_smooth, isvar, options);
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

return
end

%--------------------------------------------------------------------------
function xvar = restore_individual(xvar0, idvar, secmgr, ...
  height_smooth, isvar, options)
%restore_individual - 1候補の梁せい分布平滑化違反を復元
%
%   xvar = restore_individual(xvar0, idvar, secmgr, height_smooth, ...
%     isvar, options) は、1候補の梁せい分布平滑化違反を整数計画で
%   解消する。直前に動かした変数と固定変数は現在値から動かさない。
%
%   入力引数:
%     xvar0         - 復元前の変数値候補 [1×nx]
%     idvar         - 直前に動かした変数のグローバルID（0=指定なし）
%     secmgr        - SectionManagerインスタンス
%     height_smooth - 平滑化の固定データ（idvarH, Dmat）
%     isvar         - 設計変数フラグ [nx×1]（偽=固定）
%     options       - 共通オプション
%
%   出力引数:
%     xvar - 復元後の変数値候補。復元不要の場合は空配列 [1×nx]

% 準備
xvar = [];
consider_hsvar = options.coptions.consider_girder_height_smooth_var;

% 梁の対象断面がなければ終了
if ~consider_hsvar
  return
end
conhsvar = calc_girder_height_smooth_var(xvar0, height_smooth);
if all(conhsvar<=options.tau)
  return
end

% 平滑化対象の梁せい変数
idvarH = height_smooth.idvarH;
varH0 = xvar0(idvarH);
nv = length(idvarH);

% 整数計画の準備
x0 = round(varH0(:)/50);
xu = x0; xl = x0;

% 上下限値＝規格値ワンサイズアップ／ダウン
dH = 150;
for iv=1:nv
  % 直前に動かした変数と固定変数は動かさない（xu=xl=現在値を維持）
  % 判定はグローバル変数IDで行う（iv は idvarH 内の局所位置）
  if idvarH(iv)==abs(idvar) || ~isvar(idvarH(iv))
    continue
  end
  [~, xup, xdw] = secmgr.enumerateNeighborH(xvar0, idvarH(iv), ...
    options, dH);
  if ~isempty(xup)
    xu(iv) = round(xup(end,idvarH(iv))/50);
  end
  if ~isempty(xdw)
    xl(iv) = round(xdw(end,idvarH(iv))/50);
  end
end

% 同一符号列の差分行列を制約評価と共有する。
Dmat = height_smooth.Dmat;
ns = size(Dmat,1);
N = 3*nv+ns;
f = [zeros(1,nv) ones(1,nv) ones(1,nv) 10*ones(1,ns)]';
A = [Dmat zeros(ns,nv*2) -eye(ns)];
b = zeros(ns,1);

% スラック変数
Aeq = zeros(nv,N);
beq = x0;
for i=1:nv
  Aeq(i,[i i+nv i+nv*2]) = [1 -1 1];
end

% 変数の設定
s0 = Dmat*x0;
s0(s0<0) = 0;
y0 = [x0; zeros(nv*2,1); s0];
lb = [xl; zeros(nv*2,1); zeros(ns,1)];
ub = [xu; x0-xl; xu-x0; s0];

% オプション設定
lpopt = optimoptions('intlinprog', 'Display', 'off');

% 求解
intcon = 1:nv;
ysol = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,y0,lpopt);
Hsol = round(ysol(1:nv))*50;
xvar = xvar0;
xvar(idvarH) = Hsol;
return
end
