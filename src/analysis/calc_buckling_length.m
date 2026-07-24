function [lk, result] = calc_buckling_length(Iy, mtype, ...
  js, je, is_girder, wg, lg_end, lnm, lm, lm_bk, Em, ...
  mejoint, nominal, idmc2nc, options, beta, ilc, col_idstory, ...
  onfg, kcUser)
%calc_buckling_length - 柱部材の座屈長さを計算する（1方向分）
%
%   [lk, result] = calc_buckling_length(Iy, mtype, js, je, ...
%     is_girder, wg, lg_end, lnm, lm, lm_bk, Em, mejoint, nominal, ...
%     idmc2nc, options, beta, ilc, col_idstory, onfg, kcUser) は、
%   構造骨組みにおける柱部材の座屈長さを算出する。第2出力を
%   要求した場合だけ、座屈長さ係数と帳票用中間値を返す。
%
%   入力引数:
%     Iy          - 断面2次モーメント [nme×1]
%     mtype       - 部材タイプ配列 [nme×1]
%     js          - 部材始端節点番号 [nme×1]
%     je          - 部材終端節点番号 [nme×1]
%     is_girder   - 該当方向の梁マスク [nme×1]
%     wg          - 梁剛比の平面振れ角重み cos2θ [nme×1]
%                   （SS7互換: 水平面内の振れ角のみ考慮）
%     lg_end      - 梁端別の剛比長さ [nme×2]
%     lnm         - 通し部材の構造心間距離 [nme×1]
%     lm          - セグメント芯間距離（構造心間、控除前）[nme×1]
%                   S柱断面算定表の Lb1/Lb2 表示用
%     lm_bk       - セグメント芯間距離（端部控除後）[nme×1]
%                   柱座屈長さ表・Lk 算定用
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
%     result - 座屈長さ係数と帳票用中間値 (struct)

% 定数
nme = length(mtype);
nnc = size(nominal.column.idmec,1);
BK_MAX_IG_LG = 9999.99e3;  % 梁剛比上限 [mm3]
need_result = nargout == 2;

% ヤング係数比で補正
Iy = Iy.*Em/max(Em);

% 計算の準備
nominal_column = nominal.column;
% 名目柱ループの table 要素参照を避けるため配列へ退避する
nc_idsub = nominal_column.idsub;
nc_idmec = nominal_column.idmec;
idmc2m = 1:nme;
idmc2m = idmc2m(mtype==PRM.COLUMN)';
Gast = zeros(1,nnc); Gbst = zeros(1,nnc);
% 帳票用中間値はループ内で常時書き込み、末尾の result 組立だけを
% need_result でガードする（ループ内の個別ガードを避ける）
bk_IcLc = zeros(1,nnc);
bk_sumIcTop = zeros(1,nnc);
bk_sumIcBot = zeros(1,nnc);
bk_sumIgTop = zeros(1,nnc);
bk_sumIgBot = zeros(1,nnc);

% 控除前（S柱断面算定表 Lb1/Lb2 表示用）と控除後（Lk 算定用）の
% 2系統を 1 回の境界判定走査で同時に算出する
lmc = lm(mtype==PRM.COLUMN);
lmc_bk = lm_bk(mtype==PRM.COLUMN);
onfg_col = onfg;
[lbc_nominal, lbc_nominal_bk] = calc_nominal_lb_column(lmc, lmc_bk, ...
  nominal_column, js, je, is_girder, onfg_col, idmc2m);

% 剛比計算用の部材長（構造心間距離）
lmn = lnm;

% 剛比計算
immm = 1:nme;
for inc = 1:nnc

  % 柱頭・柱脚の判定
  idsub = nc_idsub(inc,1:2);
  nsub = idsub(2);
  idmec = nc_idmec(inc,1:nsub);
  idme = idmc2m(idmec);
  ima = idme(nsub);     % 柱頭側部材番号
  imb = idme(1);        % 柱脚側部材番号
  jsi = js(imb);
  jei = je(ima);
  lmni = lmn(imb);
  isself = false(nme,1); isself(idme) = true;

  % 接続部材番号（方向は呼び出し側で解決済み）
  % 柱は脚→頭の順に登録されている前提で、上階柱は柱頭節点を始点と
  % する柱、下階柱は柱脚節点を終点とする柱に限定する。これにより、
  % 節点同一化で同じ節点へ終端する隣柱（兄弟柱）を除外できる。
  mga = immm((js==jei | je==jei) & is_girder);
  mgb = immm((js==jsi | je==jsi) & is_girder);
  mca = immm(js==jei & mtype==PRM.COLUMN & ~isself);
  mcb = immm(je==jsi & mtype==PRM.COLUMN & ~isself);

  % 柱の剛比計算
  gc = Iy(imb)/lmni;
  if ~isempty(mca)
    gca = sum(Iy(mca)./lmn(mca));
  else
    gca = 0;
  end
  if ~isempty(mcb)
    gcb = sum(Iy(mcb)./lmn(mcb));
  else
    gcb = 0;
  end

  % 帳票用中間値の保存
  bk_IcLc(inc) = gc;
  bk_sumIcTop(inc) = gc + gca;
  bk_sumIcBot(inc) = gc + gcb;

  % 上側節点（柱頭）
  if isempty(mga)
    sumIgTop = 0;
  else
    gga = wg(mga).*Iy(mga)./select_girder_end_length(mga, jei);
    [ispin_self, ispin_other] = check_pinjoint(mga, je(ima));
    gga(ispin_self) = 0;
    gga(ispin_other) = gga(ispin_other)*0.5;
    sumIgTop = sum(gga);
  end
  bk_sumIgTop(inc) = min(sumIgTop, BK_MAX_IG_LG);
  if mejoint(ima,2)==PRM.PIN || sumIgTop<=0
    Ga = 10.0;
  else
    Ga = (gc+gca)/sumIgTop;
  end

  % 下側節点（柱脚）
  if isempty(mgb)
    sumIgBot = 0;
  else
    ggb = wg(mgb).*Iy(mgb)./select_girder_end_length(mgb, jsi);
    [ispin_self, ispin_other] = check_pinjoint(mgb, js(imb));
    ggb(ispin_self) = 0;
    ggb(ispin_other) = ggb(ispin_other)*0.5;
    sumIgBot = sum(ggb);
  end
  bk_sumIgBot(inc) = min(sumIgBot, BK_MAX_IG_LG);
  if mejoint(imb,1)==PRM.PIN || sumIgBot<=0
    Gb = 10.0;
  else
    Gb = (gc+gcb)/sumIgBot;
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
    nsub = nc_idsub(inc, 2);
    idmec = nc_idmec(inc, 1:nsub);
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
    imec_primary = nc_idmec(inc, 1);
    userK = kcUser(imec_primary);
    if ~isnan(userK)
      kcn(inc) = userK;
      kcn_raw(inc) = userK;
    end
  end
end

% 座屈長さの組み立て
kc = kcn(idmc2nc(:,1));
lbmax = lbc_nominal_bk(idmc2nc(:,1), 3);
lk = lm_bk(:);
lk(mtype==PRM.COLUMN) = kc.*lbmax;

if ~need_result
  return
end

% 座屈長さ係数と帳票用中間値
result.kc = kc;
result.kcNominal = kcn(:);
result.IcLc = bk_IcLc(:);
result.sumIcTop = bk_sumIcTop(:);
result.sumIcBot = bk_sumIcBot(:);
result.sumIgTop = bk_sumIgTop(:);
result.sumIgBot = bk_sumIgBot(:);
result.GA = Gast(:);
result.GB = Gbst(:);
result.kcRaw = kcn_raw(:);
result.lbc_nominal = make_lbc_result(lbc_nominal);
result.lbc_nominal_bk = make_lbc_result(lbc_nominal_bk);

return
%--------------------------------------------------------------
  function lg = select_girder_end_length(mg, jc)
    %select_girder_end_length - 接続端に対応する梁剛比長を返す

    mg = mg(:);
    iend = ones(numel(mg), 1);
    iend(je(mg) == jc) = 2;
    idx = sub2ind(size(lg_end), mg, iend);
    lg = lg_end(idx);
    return
  end
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
function result = make_lbc_result(lbc)
%make_lbc_result - 補剛間隔行列をstruct-of-arraysへ変換する
%
%   result = make_lbc_result(lbc) は、is、ie、max、countの列を持つ
%   補剛間隔行列を、同名フィールドを持つ構造体へ変換する。

result.is = lbc(:, 1);
result.ie = lbc(:, 2);
result.max = lbc(:, 3);
result.count = lbc(:, 4);

return
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
%     A       - 係数ベクトル A = GA.*GB
%     B       - 係数ベクトル B = GA+GB
%     a_init  - 区間の下限
%     b_init  - 区間の上限
%     tol     - 収束判定用許容誤差
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
