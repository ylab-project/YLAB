function [lkx, lky, kcx, kcy] = calc_buckling_length( ...
  Iy, mtype, js, je, dir_girder, lm, lrm, lb, ...
  Em, mejoint, nominal, idmc2nc, options)
% 柱部材の座屈長さを計算する
%
% この関数は、構造骨組みにおける柱部材の座屈長さを算出する。
% 接続する梁部材の剛比を考慮して座屈長さ係数を計算し、
% X方向およびY方向の座屈長さを決定する。
%
% Syntax
%   [lkx, lky, kcx, kcy] = calc_buckling_length(Iy, mtype, js, je, ...
%     dir_girder, lm, lrm, lb, Em, mejoint, nominal, idmc2nc, options)
%
% Inputs
%   Iy (double array): 部材の断面2次モーメント
%   mtype (double array): 部材タイプ配列
%   js (double array): 部材始端節点番号
%   je (double array): 部材終端節点番号
%   dir_girder (double array): 梁部材方向（X/Y）
%   lm (double array): 部材長（構造心間）
%   lrm (double array): 部材長（梁面からの長さ）
%   lb (double array): 補剛間隔配列
%   Em (double array): ヤング係数
%   mejoint (double array): 接合条件配列（1:X柱脚, 2:X柱頭, 3:Y柱脚, 4:Y柱頭）
%   nominal (struct): 名目部材情報
%   idmc2nc (double array): 部材-名目部材対応表
%   options (struct): 計算オプション
%
% Outputs
%   lkx (double array): X方向座屈長さ
%   lky (double array): Y方向座屈長さ
%   kcx (double array): X方向座屈長さ係数
%   kcy (double array): Y方向座屈長さ係数
%
% Example
%   >> [lkx, lky, kcx, kcy] = calc_buckling_length(Iy, mtype, js, je, ...
%        dir_girder, lm, lrm, lb, Em, mejoint, nominal, idmc2nc, options);
%   >> disp(['X方向座屈長さ: ', num2str(lkx(1))]);
%   X方向座屈長さ: 3.5

% 定数
nme = length(mtype);
nmc = sum(+(mtype==PRM.COLUMN));
% nmb = sum(+(mtype==PRM.BRACE));
nmg = sum(+(mtype==PRM.GIRDER));
nnc = size(nominal.column.idmec,1);

% ヤング係数比で補正
% Iy0 = Iy;
% Iz0 = Iz;
Iy = Iy.*Em/max(Em);

% 計算の準備
nominal_column = nominal.column;
idmc2m = 1:nme; idmc2m = idmc2m(mtype==PRM.COLUMN)';
idm2mc = zeros(nme,1); idm2mc(mtype==PRM.COLUMN) = 1:nmc;
% idmg2m = 1:nme; idmg2m = idmg2m(mtype==PRM.GIRDER)';
% iy = zeros(1,nme); iz = zeros(1,nme);
% lamy = zeros(1,nme); lamz = zeros(1,nme);
anx = zeros(1,nnc); bnx = zeros(1,nnc);
any = zeros(1,nnc); bny = zeros(1,nnc);
Gaxst = zeros(1,nnc); Gbxst = zeros(1,nnc);
Gayst = zeros(1,nnc); Gbyst = zeros(1,nnc);

% 剛域を除外した柱補剛間隔
lrcm = lrm(mtype==PRM.COLUMN,:);
lrcxn = calc_nominal_lb_column(lrcm(:,1), nominal_column);
lrcyn = calc_nominal_lb_column(lrcm(:,2), nominal_column);

% 通し柱の最大補剛間隔
lrcxnmax = lrcxn.max;
lrcynmax = lrcyn.max;

% TODO: とりあえず
dir_girder_ = dir_girder;
dir_girder = zeros(nme,1);
dir_girder(mtype==PRM.GIRDER) = dir_girder_;

% 通し柱を考慮した部材長の計算：節点間距離
lmn = lm;

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

  % 接続部材番号
  % 45度梁（PRM.XY）は両方向に含める
  mgax = immm((js==jei | je==jei) & (dir_girder==PRM.X|dir_girder==PRM.XY));
  mgay = immm((js==jei | je==jei) & (dir_girder==PRM.Y|dir_girder==PRM.XY));
  mgbx = immm((js==jsi | je==jsi) & (dir_girder==PRM.X|dir_girder==PRM.XY));
  mgby = immm((js==jsi | je==jsi) & (dir_girder==PRM.Y|dir_girder==PRM.XY));
  mca  = immm((js==jei | je==jei) & mtype==PRM.COLUMN & ~isself);
  mcb  = immm((js==jsi | je==jsi) & mtype==PRM.COLUMN & ~isself);

  % 節点同一化により複数柱が接続する場合はエラー
  if length(mca) > 1
    error('節点に上側から2本以上の柱が接続しています');
  end
  if length(mcb) > 1
    error('節点に下側から2本以上の柱が接続しています');
  end

  % 柱の剛比計算（座屈長さ係数の計算時は構造心間の長さ）
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

  % --------------------------------
  % X方向
  % --------------------------------
  % 上側節点
  if isempty(mgax) || mejoint(ima,2)==PRM.PIN
    Gax = 10.0;
  else
    ggax = Iy(mgax)./lm(mgax);
    [ispin_self, ispin_other] = check_pinjoint(mgax, je(ima));
    ggax(ispin_self) = 0;
    ggax(ispin_other) = ggax(ispin_other)*0.5;
    if sum(ggax)>0
      Gax = (gc+gca)/sum(ggax);
    else
      Gax = 10.0;
    end
  end

  % 下側節点
  if isempty(mgbx) || mejoint(ima,1)==PRM.PIN
    Gbx = 10.0;
  else
    ggbx = Iy(mgbx)./lm(mgbx);
    [ispin_self, ispin_other] = check_pinjoint(mgbx, js(imb));
    ggbx(ispin_self) = 0;
    ggbx(ispin_other) = ggbx(ispin_other)*0.5;
    if sum(ggbx)>0
      Gbx = (gc+gcb)/sum(ggbx);
    else
      Gbx = 10.0;
    end
  end

  % % 下限値の処理
  % Gax = max(Gax,0.001);
  % Gbx = max(Gbx,0.001);

  % 係数計算
  anx(inc) = -Gax*Gbx/(6*(Gax+Gbx));
  bnx(inc) = -6/(Gax+Gbx);

  % ---- 確認用 ---
  Gaxst(inc) = Gax;
  Gbxst(inc) = Gbx;

  % --------------------------------
  % Y方向
  % --------------------------------
  % 上側節点
  if isempty(mgay) || mejoint(ima,4)==PRM.PIN
    Gay = 10.0;
  else
    ggay = Iy(mgay)./lm(mgay);
    [ispin_self, ispin_other] = check_pinjoint(mgay, je(ima));
    ggay(ispin_self) = 0;
    ggay(ispin_other) = ggay(ispin_other)*0.5;
    if sum(ggay)>0
      Gay = (gc+gca)/sum(ggay);
    else
      Gay = 10.0;
    end
  end

  % 下側節点
  if isempty(mgby) || mejoint(ima,3)==PRM.PIN
    Gby = 10.0;
  else
    ggby = Iy(mgby)./lm(mgby);
    [ispin_self, ispin_other] = check_pinjoint(mgby, js(imb));
    ggby(ispin_self) = 0;
    ggby(ispin_other) = ggby(ispin_other)*0.5;
    if sum(ggby)>0
      Gby = (gc+gcb)/sum(ggby);
    else
      Gby = 10.0;
    end
  end

  % % 下限値の処理
  % Gay = max(Gay,0.001);
  % Gby = max(Gby,0.001);

  % 係数計算
  any(inc) = -Gay*Gby/(6*(Gay+Gby));
  bny(inc) = -6/(Gay+Gby);

  % ---- 確認用 ---
  Gayst(inc) = Gay;
  Gbyst(inc) = Gby;
end

% 座屈長さ係数の計算（2分法）
kcxn = solveK(Gaxst, Gbxst, 1e-3);
kcyn = solveK(Gayst, Gbyst, 1e-3);

% 結果の整理
kcx = kcxn(idmc2nc(:,1));
kcy = kcyn(idmc2nc(:,1));
lrcxmax = lrcxnmax(idmc2nc(:,1));
lrcymax = lrcynmax(idmc2nc(:,1));

% 座屈長さの初期化（梁面からの長さ）
lkx = zeros(nme,1);
lky = zeros(nme,3);
lkx(:,1) = lrm(:,1);
lky(:,1) = lrm(:,2);
if options.consider_column_buckling_length_factor
  lkx(mtype==PRM.COLUMN,1) = kcx.*lrcxmax;
  lky(mtype==PRM.COLUMN,1) = kcy.*lrcymax;
else
  lkx(mtype==PRM.COLUMN,1) = lrcxmax;
  lky(mtype==PRM.COLUMN,1) = lrcymax;
end

% 梁用
lky(mtype==PRM.GIRDER,:) = lb(mtype==PRM.GIRDER,:);

return

%--------------------------------------------------------------------------
  function [ispin_self, ispin_other] = check_pinjoint(mg, jc)
    % ピン接合条件をチェックする
    %
    % この関数は、指定された梁部材のピン接合条件を確認する。
    % 接続端および接続他端のピン接合状態を判定する。
    %
    % Syntax
    %   [ispin_self, ispin_other] = check_pinjoint(mg, jc)
    %
    % Inputs
    %   mg (double array): 対象梁部材番号配列
    %   jc (double): 対象節点番号
    %
    % Outputs
    %   ispin_self (logical array): 接続端がピン接合かどうか
    %   ispin_other (logical array): 接続他端がピン接合かどうか

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
  end
end

%--------------------------------------------------------------------------
function K = solveK(GA, GB, tol)
% 2分法で座屈長さ係数を解く
%
% この関数は、2分法を用いて座屈長さ係数の非線形方程式を解く。
% 各終端の剛性比に対して対応する座屈長さ係数を算出する。
%
% Syntax
%   K = solveK(GA, GB)
%   K = solveK(GA, GB, tol)
%
% Inputs
%   GA (double array): 柱頭側剛性比配列
%   GB (double array): 柱脚側剛性比配列
%   tol (double): 収束判定用許容誤差 (default: 1e-12)
%
% Outputs
%   K (double array): 座屈長さ係数配列（収束しない場合はNaN）
%
% Example
%   >> GA = [1.0, 2.0]; GB = [1.5, 2.5];
%   >> K = solveK(GA, GB);
%   >> disp(K);

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

% 区間 (pi/2, pi) での探索（まだ解が見つかっていない要素のみ）
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
end

%--------------------------------------------------------------------------
function f = buckling_equation(A, B, x)
% 座屈長さ係数の非線形方程式を評価する
%
% この関数は、柱の座屈長さ係数を求めるための非線形方程式
% (A.*x.^2 - 36).*tan(x) - 6*B.*x = 0 を評価する。
%
% Syntax
%   f = buckling_equation(A, B, x)
%
% Inputs
%   A (double array): 係数 A = GA.*GB（柱頭・柱脚剛性比の積）
%   B (double array): 係数 B = GA+GB（柱頭・柱脚剛性比の和）
%   x (double): 評価点
%
% Outputs
%   f (double array): 方程式の値
%
% Example
%   >> A = [2.0, 3.0]; B = [4.0, 5.0]; x = 1.5;
%   >> f = buckling_equation(A, B, x);
%   >> disp(f);

f = (A.*x.^2 - 36).*tan(x) - 6*B.*x;
end

%--------------------------------------------------------------------------
function x = bisect_vectorized(A, B, a_init, b_init, tol, maxIter)
% ベクトル化された2分法で方程式の根を求める
%
% この関数は、2分法を用いて複数の座屈長さ係数方程式を同時に解く。
% 各要素は同じ区間[a_init, b_init]で探索される。
%
% Syntax
%   x = bisect_vectorized(A, B, a_init, b_init, tol, maxIter)
%
% Inputs
%   A (double array): 係数ベクトル A = GA.*GB
%   B (double array): 係数ベクトル B = GA+GB
%   a_init (double): 区間の下限
%   b_init (double): 区間の上限
%   tol (double): 収束判定用許容誤差
%   maxIter (double): 最大反復回数
%
% Outputs
%   x (double array): 各方程式の根

n = length(A);
x = nan(n, 1);

% 初期化
a = repmat(a_init, n, 1);
b = repmat(b_init, n, 1);
active = true(n, 1);  % まだ収束していない要素

for k = 1:maxIter
  if ~any(active)
    break
  end

  % アクティブな要素のインデックスを取得
  act_idx = find(active);
  n_active = length(act_idx);

  if n_active == 0
    break
  end

  % アクティブな要素のみ計算
  c_act = 0.5 * (a(act_idx) + b(act_idx));
  fc_act = buckling_equation(A(act_idx), B(act_idx), c_act);
  fa_act = buckling_equation(A(act_idx), B(act_idx), a(act_idx));

  % 収束判定
  converged = abs(fc_act) < tol | 0.5*abs(b(act_idx) - a(act_idx)) < tol;

  % 収束した要素を結果に格納
  conv_global_idx = act_idx(converged);
  if any(converged)
    x(conv_global_idx) = c_act(converged);
    active(conv_global_idx) = false;
  end

  % まだ収束していない要素の区間更新
  not_converged = ~converged;
  if any(not_converged)
    not_conv_global_idx = act_idx(not_converged);
    c_not_conv = c_act(not_converged);
    fc_not_conv = fc_act(not_converged);
    fa_not_conv = fa_act(not_converged);

    % 根の位置判定
    left_side = fa_not_conv .* fc_not_conv < 0;

    % 区間更新
    left_idx = not_conv_global_idx(left_side);
    right_idx = not_conv_global_idx(~left_side);

    b(left_idx) = c_not_conv(left_side);
    a(right_idx) = c_not_conv(~left_side);
  end
end

% 収束しなかった要素に警告
if any(active)
  warning('bisect_vectorized:NoConverge', ...
    'ベクトル化2分法で %d 個の要素が最大反復に到達しました', sum(active));
end
end
