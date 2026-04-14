function [lk, kc, bkinfo] = calc_buckling_length(Iy, mtype, ...
  js, je, is_girder, lnm, lm, Em, mejoint, nominal, ...
  idmc2nc, options, beta, ilc, col_idstory, onfg, kcUser)
%calc_buckling_length - 柱部材の座屈長さを計算する（1方向分）
%
%   [lk, kc, bkinfo] = calc_buckling_length(Iy,
%   mtype, js, je, is_girder, lnm, lm, Em, mejoint,
%   nominal, idmc2nc, options, beta, ilc,
%   col_idstory, onfg, kcUser) は、
%   構造骨組みにおける柱部材の座屈長さを算出する。
%   呼び出し側で方向別の引数を準備し、本関数を
%   X方向・Y方向それぞれ1回ずつ呼び出す。
%
%   入力引数:
%     Iy          - 断面2次モーメント [nme×1]
%     mtype       - 部材タイプ配列 [nme×1]
%     js          - 部材始端節点番号 [nme×1]
%     je          - 部材終端節点番号 [nme×1]
%     is_girder   - 該当方向の梁マスク [nme×1]
%     lnm         - 通し部材の構造心間距離 [nme×1]
%     lm          - セグメント芯間距離 [nme×1]
%     Em          - ヤング係数 [nme×1]
%     mejoint     - 接合条件 [nme×2]（柱脚,柱頭）
%     nominal     - 名目部材情報 (struct)
%     idmc2nc     - 部材-名目部材対応表
%     options     - 計算オプション (struct)
%     beta        - ブレース水平力分担率
%     ilc         - 荷重ケースマスク [nlc×1]
%     col_idstory - 柱部材の層番号
%     onfg        - 基礎梁接続フラグ [nmc×1]
%     kcUser      - ユーザー指定座屈長さ係数 [nmec×1]
%                   NaN=自動計算、数値=直接入力値
%
%   出力引数:
%     lk     - 座屈長さ [nme×1]
%     kc     - 座屈長さ係数 [nmc×1]
%     bkinfo - 中間値 (struct)

% 定数
nme = length(mtype);
nnc = size(nominal.column.idmec,1);
BK_MAX_IG_LG = 9999.99e3;  % 梁剛比上限 [mm3]

% ヤング係数比で補正
Iy = Iy.*Em/max(Em);

% 計算の準備
nominal_column = nominal.column;
idmc2m = 1:nme;
idmc2m = idmc2m(mtype==PRM.COLUMN)';
Gast = zeros(1,nnc); Gbst = zeros(1,nnc);
bk_IcLc = zeros(1,nnc);
bk_sumIcTop = zeros(1,nnc);
bk_sumIcBot = zeros(1,nnc);
bk_sumIgTop = zeros(1,nnc);
bk_sumIgBot = zeros(1,nnc);

% 横補剛間隔（横補剛点判定付き、節点間距離ベース）
lmc = lm(mtype==PRM.COLUMN);
onfg_col = onfg;
lbcn = calc_nominal_lb_column(lmc, nominal_column, js, je, ...
  is_girder, onfg_col, idmc2m);

% 通し柱の最大補剛間隔
lbcnmax = lbcn.max;

% 剛比計算用の部材長（構造心間距離）
lmn = lnm;

% 剛比計算
immm = 1:nme;
for inc = 1:nnc

  % 柱頭・柱脚の判定
  idsub = nominal_column.idsub(inc,1:2);
  nsub = idsub(2);
  idmec = nominal_column.idmec(inc,1:nsub);
  idme = idmc2m(idmec);
  ima = idme(nsub);     % 柱頭側部材番号
  imb = idme(1);        % 柱脚側部材番号
  jsi = js(imb);
  jei = je(ima);
  lmni = lmn(imb);
  isself = false(nme,1); isself(idme) = true;

  % 接続部材番号（方向は呼び出し側で解決済み）
  mga = immm((js==jei | je==jei) & is_girder);
  mgb = immm((js==jsi | je==jsi) & is_girder);
  mca = immm((js==jei | je==jei) & mtype==PRM.COLUMN & ~isself);
  mcb = immm((js==jsi | je==jsi) & mtype==PRM.COLUMN & ~isself);

  % 複数柱接続エラー
  if length(mca) > 1
    error('節点に上側から2本以上の柱が接続しています');
  end
  if length(mcb) > 1
    error('節点に下側から2本以上の柱が接続しています');
  end

  % 柱の剛比計算
  gc = Iy(imb)/lmni;
  if ~isempty(mca)
    gca = Iy(mca)/lmn(mca);
  else
    gca = 0;
  end
  if ~isempty(mcb)
    gcb = Iy(mcb)/lmn(mcb);
  else
    gcb = 0;
  end

  % 中間値の保存
  bk_IcLc(inc) = gc;
  bk_sumIcTop(inc) = gc + gca;
  bk_sumIcBot(inc) = gc + gcb;

  % 上側節点（柱頭）
  if isempty(mga) || mejoint(ima,2)==PRM.PIN
    Ga = 10.0;
  else
    gga = Iy(mga)./lnm(mga);
    [ispin_self, ispin_other] = check_pinjoint(mga, je(ima));
    gga(ispin_self) = 0;
    gga(ispin_other) = gga(ispin_other)*0.5;
    bk_sumIgTop(inc) = min(sum(gga), BK_MAX_IG_LG);
    if bk_sumIgTop(inc)>0
      Ga = (gc+gca)/bk_sumIgTop(inc);
    else
      Ga = 10.0;
    end
  end

  % 下側節点（柱脚）
  if isempty(mgb) || mejoint(ima,1)==PRM.PIN
    Gb = 10.0;
  else
    ggb = Iy(mgb)./lnm(mgb);
    [ispin_self, ispin_other] = check_pinjoint(mgb, js(imb));
    ggb(ispin_self) = 0;
    ggb(ispin_other) = ggb(ispin_other)*0.5;
    bk_sumIgBot(inc) = min(sum(ggb), BK_MAX_IG_LG);
    if bk_sumIgBot(inc)>0
      Gb = (gc+gcb)/bk_sumIgBot(inc);
    else
      Gb = 10.0;
    end
  end

  Gast(inc) = Ga;
  Gbst(inc) = Gb;
end

% 座屈長さ係数の計算
if options.consider_column_buckling_length_factor
  % 自動計算: 2分法で solve → β補正
  kcn = solveK(Gast, Gbst, 1e-3);
  kcn_raw = kcn;
  alpha = options.brace_share_threshold;
  for inc = 1:nnc
    nsub = nominal_column.idsub(inc, 2);
    idmec = nominal_column.idmec(inc, 1:nsub);
    ist = col_idstory(idmec);
    if any(ilc)
      bmin = min(beta(ist, ilc), [], 'all');
      if bmin >= alpha
        kcn(inc) = 1.0;
      else
        r = bmin / alpha;
        kcn(inc) = kcn_raw(inc) * (1 - r) + r;
      end
    end
  end
else
  % 自動計算OFF: デフォルト K=1.0（ユーザー指定が無い柱に適用）
  kcn = ones(nnc, 1);
  kcn_raw = kcn;
end

% ユーザー入力K値で上書き（自動計算・β補正の結果を完全に置換）
% 通し柱は柱脚側部材（idmec(inc,1)）のユーザー指定値のみ参照する
if ~isempty(kcUser)
  for inc = 1:nnc
    imec_primary = nominal_column.idmec(inc, 1);
    userK = kcUser(imec_primary);
    if ~isnan(userK)
      kcn(inc) = userK;
      kcn_raw(inc) = userK;
    end
  end
end

% 結果の整理
kc = kcn(idmc2nc(:,1));
lbmax = lbcnmax(idmc2nc(:,1));

% 座屈長さの初期化（梁面からの長さ）
% 自動計算OFFでも kcn=1 またはユーザー指定K値になっているため常に K×Lb
lk = zeros(nme,1);
lk(:) = lm;
lk(mtype==PRM.COLUMN) = kc.*lbmax;

% 座屈長さ係数の中間値
bkinfo.IcLc = bk_IcLc(:);
bkinfo.sumIcTop = bk_sumIcTop(:);
bkinfo.sumIcBot = bk_sumIcBot(:);
bkinfo.sumIgTop = bk_sumIgTop(:);
bkinfo.sumIgBot = bk_sumIgBot(:);
bkinfo.GA = Gast(:);
bkinfo.GB = Gbst(:);
bkinfo.kcRaw = kcn_raw(:);
bkinfo.kc = kcn(:);
bkinfo.lbcnmax = lbcnmax(:);

return

%--------------------------------------------------------------
  function [ispin_self, ispin_other] = check_pinjoint(mg, jc)
    %check_pinjoint - ピン接合条件をチェックする
    %
    %   [ispin_self, ispin_other] =
    %   check_pinjoint(mg, jc) は、指定された梁部材の
    %   ピン接合条件を確認する。
    %
    %   入力引数:
    %     mg - 対象梁部材番号配列
    %     jc - 対象節点番号
    %
    %   出力引数:
    %     ispin_self  - 接続端がピン接合か
    %     ispin_other - 接続他端がピン接合か

    nmg_ = length(mg);
    ispin_self = false(1,nmg_);
    ispin_other = false(1,nmg_);

    for i_ = 1:nmg_
      jjj = [js(mg(i_)) je(mg(i_))]==jc;
      if mejoint(mg(i_), jjj) == PRM.PIN
        ispin_self(i_) = true;
      end
      if mejoint(mg(i_), ~jjj) == PRM.PIN
        ispin_other(i_) = true;
      end
    end
    return
  end
end

%--------------------------------------------------------------
function K = solveK(GA, GB, tol)
%solveK - 2分法で座屈長さ係数を解く
%
%   K = solveK(GA, GB, tol) は、2分法を用いて
%   座屈長さ係数の非線形方程式を解く。
%
%   入力引数:
%     GA  - 柱頭側剛性比配列
%     GB  - 柱脚側剛性比配列
%     tol - 収束判定用許容誤差 (default: 1e-12)
%
%   出力引数:
%     K - 座屈長さ係数配列

if nargin < 3
  tol = 1e-12;
end

epsx = 1e-6;
GA = GA(:);
GB = GB(:);
n = numel(GA);
K = nan(n,1);

maxIter = ceil(log2((pi-2*epsx)/tol)) + 2;

% ベクトル化された係数計算
A = GA .* GB;
B = GA + GB;

% 区間 (0, pi/2) での探索
a1 = epsx;
b1 = pi/2 - epsx;
fa1 = buckling_equation(A, B, a1);
fb1 = buckling_equation(A, B, b1);

% 符号変化がある要素を特定
mask1 = fa1.*fb1 < 0;
if any(mask1)
  x1 = bisect_vectorized(A(mask1), B(mask1), a1, b1, tol, maxIter);
  K(mask1) = pi./x1;
end

% 区間 (pi/2, pi) での探索
remaining = isnan(K);
if any(remaining)
  a2 = pi/2 + epsx;
  b2 = pi - epsx;
  A_rem = A(remaining);
  B_rem = B(remaining);
  fa2 = buckling_equation(A_rem, B_rem, a2);
  fb2 = buckling_equation(A_rem, B_rem, b2);

  mask2 = fa2.*fb2 < 0;
  if any(mask2)
    A_solve = A_rem(mask2);
    B_solve = B_rem(mask2);
    x2 = bisect_vectorized(A_solve, B_solve, a2, b2, tol, maxIter);

    % 元のインデックスに結果を格納
    rem_idx = find(remaining);
    solve_idx = rem_idx(mask2);
    K(solve_idx) = pi./x2;
  end
end

return
end

%--------------------------------------------------------------
function f = buckling_equation(A, B, x)
%buckling_equation - 座屈方程式を評価する
%
%   f = buckling_equation(A, B, x) は、
%   (A.*x.^2 - 36).*tan(x) - 6*B.*x = 0 を評価する。
%
%   入力引数:
%     A - 係数 A = GA.*GB
%     B - 係数 B = GA+GB
%     x - 評価点
%
%   出力引数:
%     f - 方程式の値

f = (A.*x.^2 - 36).*tan(x) - 6*B.*x;

return
end

%--------------------------------------------------------------
function x = bisect_vectorized(A, B, a_init, b_init, tol, maxIter)
%bisect_vectorized - ベクトル化2分法で根を求める
%
%   x = bisect_vectorized(A, B, a_init, b_init,
%   tol, maxIter) は、2分法を用いて複数の座屈長さ
%   係数方程式を同時に解く。
%
%   入力引数:
%     A      - 係数ベクトル A = GA.*GB
%     B      - 係数ベクトル B = GA+GB
%     a_init - 区間の下限
%     b_init - 区間の上限
%     tol    - 収束判定用許容誤差
%     maxIter - 最大反復回数
%
%   出力引数:
%     x - 各方程式の根

n = length(A);
x = nan(n, 1);

% 初期化
a = repmat(a_init, n, 1);
b = repmat(b_init, n, 1);
active = true(n, 1);

for k = 1:maxIter
  if ~any(active)
    break
  end

  act_idx = find(active);
  n_active = length(act_idx);

  if n_active == 0
    break
  end

  c_act = 0.5*(a(act_idx) + b(act_idx));
  fc_act = buckling_equation(A(act_idx), B(act_idx), c_act);
  fa_act = buckling_equation(A(act_idx), B(act_idx), a(act_idx));

  % 収束判定
  converged = abs(fc_act) < tol | 0.5*abs(b(act_idx)-a(act_idx)) < tol;

  conv_global_idx = act_idx(converged);
  if any(converged)
    x(conv_global_idx) = c_act(converged);
    active(conv_global_idx) = false;
  end

  not_converged = ~converged;
  if any(not_converged)
    not_conv_global_idx = act_idx(not_converged);
    c_not_conv = c_act(not_converged);
    fc_not_conv = fc_act(not_converged);
    fa_not_conv = fa_act(not_converged);

    left_side = fa_not_conv .* fc_not_conv < 0;

    left_idx = not_conv_global_idx(left_side);
    right_idx = not_conv_global_idx(~left_side);

    b(left_idx) = c_not_conv(left_side);
    a(right_idx) = c_not_conv(~left_side);
  end
end

% 収束しなかった要素に警告
if any(active)
  warning('bisect_vectorized:NoConverge', ...
    'ベクトル化2分法で %d 個の要素が最大反復に到達しました', ...
    sum(active));
end

return
end
