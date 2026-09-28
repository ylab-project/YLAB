function xlist = restore_column_diameter_gap(xlist0, Dgap, ...
  secmgr, isvar, options)
%restore_column_diameter_gap - 柱外径差違反の復元
%
%   xlist = restore_column_diameter_gap(xlist0, Dgap, secmgr,
%     isvar, options) は、柱外径差の違反を解消した変数値候補を生成
%   する。上下とも角形鋼管の柱のペアは外径Dを50 mm刻みの整数計画
%   で、上下ともH形鋼柱のペアはせいHの公称値の候補の組合せを列挙
%   して復元する。固定変数は近傍列挙をスキップして現在値を維持し、
%   動かさない。
%
%   入力引数:
%     xlist0  - 変数値の候補リスト [nlist×nx]
%     Dgap    - 柱外径差ペアデータ（idvar, idxy）
%     secmgr  - SectionManagerインスタンス
%     isvar   - 設計変数フラグ [nx×1]（偽=固定）
%     options - 共通オプション
%
%   出力引数:
%     xlist - 復元後の変数値候補

% 計算の準備
[nlist0, nx] = size(xlist0);
xcell = cell(nlist0,1);

% 柱外径差の解消
if (nlist0==1)
  do_parallel = false;
else
  do_parallel = options.do_parallel;
end
if do_parallel
  parfor i=1:nlist0
    xcell{i} = restore_individual(xlist0(i,:), Dgap, secmgr, ...
      isvar, options);
  end
else
  for i=1:nlist0
    xcell{i} = restore_individual(xlist0(i,:), Dgap, secmgr, ...
      isvar, options);
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
function xlist = restore_individual(xvar, Dgap, secmgr, isvar, options)
%restore_individual - 1つの変数値について通りごとに柱外径差を復元する
%
%   xlist = restore_individual(xvar, Dgap, secmgr, isvar, options) は、
%   柱外径差のペアをxy通りごとに分け、通りごとに復元した変数値を
%   現在値に続けて返す。ペアは上下が同じ断面種別の柱なので、上階柱の
%   変数の種別で角形鋼管の外径DのペアとH形鋼のせいHのペアに分け、
%   別々に復元する。
%
%   入力引数:
%     xvar    - 現在の変数値 [1×nx]
%     Dgap    - 柱外径差ペアデータ（idvar, idxy）
%     secmgr  - SectionManagerインスタンス
%     isvar   - 設計変数フラグ [nx×1]（偽=固定）
%     options - 共通オプション
%
%   出力引数:
%     xlist - 現在値と復元後の変数値 [nlist×nx]

% 準備
xlist = [];
iscdg = options.coptions.consider_column_diameter_gap;

% 柱外径差の対象断面がなければ終了
if ~iscdg
  return
end
idDgap2var = Dgap.idvar;
condgap = calc_column_diameter_gap_var(xvar, idDgap2var, options);
if all(condgap<=options.tau)
  return
end

% 準備
idxyset = Dgap.idxy;
vtype = secmgr.idvar2vtype;

% 初期化
nx = size(xvar,2);
[~, idu1, idu2] = unique(idxyset,'rows');
nxy = length(idu1);
xcell = cell(nxy,1);
lpopt = optimoptions('intlinprog', 'Display', 'off', 'MaxTime', 3);

% 通りごとに探索
for id = 1:nxy
  idg2v = idDgap2var(idu2==id, :);
  is_h_pair = vtype(idg2v(:,1)) == PRM.WFS_H;
  xsol_d = restore_pairs_d(xvar, idg2v(~is_h_pair,:), secmgr, ...
    isvar, options, lpopt);
  xsol_h = restore_pairs_h(xvar, idg2v(is_h_pair,:), secmgr, ...
    isvar, options);
  xcell{id} = [xsol_d; xsol_h];
end

% 結果の整理
nlist = 0;
for id = 1:nxy
  nlist = nlist + size(xcell{id},1);
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
end

%--------------------------------------------------------------------------
function xsol = restore_pairs_d(xvar, idg2v, secmgr, isvar, options, lpopt)
%restore_pairs_d - 上下とも角形鋼管の柱のペアの外径差を整数計画で復元する
%
%   xsol = restore_pairs_d(xvar, idg2v, secmgr, isvar, options, lpopt)
%   は、1つのxy通りにある上下とも角形鋼管の柱のペアについて、外径Dを
%   50 mm刻みの整数変数として上下1サイズの範囲で動かし、外径差の
%   違反量が最小になる変数値を返す。違反がないときと、現在値が50 mm
%   の倍数でないときは空を返す。
%
%   入力引数:
%     xvar    - 現在の変数値 [1×nx]
%     idg2v   - ペアの変数番号 [ngap×2]（1列: 上階柱、2列: 下階柱）
%     secmgr  - SectionManagerインスタンス
%     isvar   - 設計変数フラグ [nx×1]（偽=固定）
%     options - 共通オプション
%     lpopt   - intlinprog のオプション
%
%   出力引数:
%     xsol - 復元後の変数値 [1×nx]（復元しないときは [0×nx]）

nx = size(xvar,2);
xsol = zeros(0,nx);
if isempty(idg2v)
  return
end
tolMaxDgap = options.tolMaxDgap;
condgap = calc_column_diameter_gap_var(xvar, idg2v, options);
if all(condgap<=options.tau)
  return
end

% 整数計画の準備
idx2v = unique(idg2v);
nv = length(idx2v);
ngap = size(idg2v,1);
[~, idg2x] = ismember(idg2v, idx2v);
D0 = xvar(idx2v);
if any(mod(D0,50)~=0)
  return
end
x0 = [D0(:)/50; 0];
ub = [D0(:)/50; 0];
lb = [D0(:)/50; 0];

% 上下限値＝規格値ワンサイズアップ／ダウン
% 固定変数は近傍列挙をスキップし lb=ub=現在値 を維持する
for iv=1:nv
  if ~isvar(idx2v(iv))
    continue
  end
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
A = zeros(ngap*2,nv+1);
b = [zeros(ngap,1); tolMaxDgap*ones(ngap,1)/50];
for i=1:ngap
  A(i, idg2x(i,:)) = [1 -1];
  A(i+ngap, idg2x(i,:)) = [-1 1];
end
A(:,nv+1) = -1;

% 変数の設定
s0 = max(max(A(:,1:nv)*x0(1:nv)-b),0);
x0(nv+1) = s0;
ub(nv+1) = s0;

% 求解
xint = intlinprog(f,1:nv+1,A,b,[],[],lb,ub,x0,lpopt);
xsol = xvar;
xsol(idx2v) = xint(1:nv)*50;

return
end

%--------------------------------------------------------------------------
function xsol = restore_pairs_h(xvar, idg2v, secmgr, isvar, options)
%restore_pairs_h - 上下ともH形鋼柱のペアの外径差を候補の列挙で復元する
%
%   xsol = restore_pairs_h(xvar, idg2v, secmgr, isvar, options) は、
%   1つのxy通りにある上下ともH形鋼柱のペアについて、各変数の現在値と
%   近傍の公称せいを候補にして全組合せを列挙し、外径差の違反量が
%   最小、同じなら現在値からのせいの変化の合計が最小になる変数値を
%   返す。せいの候補は50 mm刻みでないため整数計画は使わない。固定
%   変数は現在値だけを候補にする。違反がないときは空を返す。
%
%   入力引数:
%     xvar    - 現在の変数値 [1×nx]
%     idg2v   - ペアの変数番号 [ngap×2]（1列: 上階柱、2列: 下階柱）
%     secmgr  - SectionManagerインスタンス
%     isvar   - 設計変数フラグ [nx×1]（偽=固定）
%     options - 共通オプション
%
%   出力引数:
%     xsol - 復元後の変数値 [1×nx]（復元しないときは [0×nx]）

nx = size(xvar,2);
xsol = zeros(0,nx);
if isempty(idg2v)
  return
end
condgap = calc_column_diameter_gap_var(xvar, idg2v, options);
if all(condgap<=options.tau)
  return
end

% 変数ごとの候補値（現在値と上下の公称せい）
idx2v = unique(idg2v);
nv = length(idx2v);
cands = cell(nv,1);
for iv=1:nv
  iv2v = idx2v(iv);
  cands{iv} = xvar(iv2v);
  if isvar(iv2v)
    [~, xup, xdw] = secmgr.enumerateNeighborH(xvar, iv2v, options);
    cands{iv} = unique([xvar(iv2v); xup(:,iv2v); xdw(:,iv2v)]);
  end
end

% 全組合せの列挙
grids = cell(nv,1);
[grids{:}] = ndgrid(cands{:});
ncomb = numel(grids{1});
combos = zeros(ncomb, nv);
for iv=1:nv
  combos(:,iv) = grids{iv}(:);
end

% 違反量（上階柱が下階柱より大きい量と、差が許容差を超える量の最大）
% が最小、同じなら現在値からの変化の合計が最小の組を採用する
[~, idg2x] = ismember(idg2v, idx2v);
gap = combos(:, idg2x(:,1)) - combos(:, idg2x(:,2));
violation = max(max(max(gap, -gap - options.tolMaxDgap), [], 2), 0);
distance = sum(abs(combos - reshape(xvar(idx2v), 1, nv)), 2);
[~, ibest] = sortrows([violation distance]);
xsol = xvar;
xsol(idx2v) = combos(ibest(1),:);

return
end
