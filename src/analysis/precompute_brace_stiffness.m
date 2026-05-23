function br_stif = precompute_brace_stiffness(A, ...
  cxl, cyl, lm, Em, JJ, Gm, xr, yr, idn2df, idm2n1, ...
  idm2n2, mtype, stype, idm2s, is_tension_only, factor_J)
%precompute_brace_stiffness - 全ブレース剛性の事前計算
%
%   br_stif = precompute_brace_stiffness(...) は、
%   全ブレース部材のトラス剛性を事前計算し、構造体
%   配列を返す。TB/非TBを統一的に扱う。
%
%   入力引数:
%     A - 断面積 [nme×1]
%     cxl - 部材座標系x方向余弦 [nme×3]
%     cyl - 部材座標系y方向余弦 [nme×3]
%     lm - 部材長 [nme×1]
%     Em - ヤング係数 [nme×1]
%     JJ - ねじり定数 [nme×1]
%     Gm - せん断弾性係数 [nme×1]
%     xr, yr - 剛床中心からの相対座標 [nnode×1]
%     idn2df - 節点-自由度変換 [nnode×6]
%     idm2n1, idm2n2 - 部材端節点 [nme×1]
%     mtype - 部材種別 [nme×1]
%     stype - 断面種別 [nsec×1]
%     idm2s - 部材-断面変換 [nme×1]
%     is_tension_only - 引張のみ判定 [nme×1]
%     factor_J - 捩り剛性増減率 [nme×1]（0 は微小化対象）
%
%   出力引数:
%     br_stif - 構造体配列 [nbr×1]
%       im    - 全体部材番号
%       ke    - 全体座標系剛性行列 [12×12]
%       tt    - トラス変換行列 [2×12]
%       kn    - 軸剛性 EA/L [N/mm]
%       ndi   - 自由度番号 [1×12]
%       is_tb - 引張ブレースフラグ

% 全ブレース部材の特定
is_brace = (mtype == PRM.BRACE) | (mtype == PRM.HORIZONTAL_BRACE);
id_br = find(is_brace);
nbr = length(id_br);

if nbr == 0
  br_stif = struct('im', {}, 'ke', {}, 'tt', {}, ...
    'kn', {}, 'ndi', {}, 'is_tb', {});
  return
end

% TB判定（収束ループでの剛性減算対象）
is_tb = ((mtype == PRM.BRACE) ...
  & (stype(idm2s) == PRM.TB | is_tension_only)) ...
  | ((mtype == PRM.HORIZONTAL_BRACE) & is_tension_only);

% 方向余弦
czl = cross(cxl, cyl, 2);
z = zeros(3, 3);

% 構造体配列の初期化
br_stif(nbr) = struct('im', 0, 'ke', zeros(12), ...
  'tt', zeros(2, 12), 'kn', 0, 'ndi', zeros(1, 12), ...
  'is_tb', false);

% 捩り剛性増減率（0 は STIFF_IGNORE_FACTOR に置換、数値問題回避）
J_fac = factor_J;
J_fac(J_fac == 0) = PRM.STIFF_IGNORE_FACTOR;

for idx = 1:nbr
  im = id_br(idx);
  li = lm(im); Ai = A(im); Ei = Em(im);
  kn_i = Ei * Ai / li;

  % 局所座標系ke（軸+ねじり）
  ke = stif_truss_matrix(li, Ai, Ei, JJ(im) * J_fac(im), Gm(im));

  % 局所系→全体系変換
  t_ = [cxl(im,:); cyl(im,:); czl(im,:)];
  tm = [t_ z z z; z t_ z z; z z t_ z; z z z t_];
  ke = tm' * ke * tm;

  % 剛床変換
  in1 = idm2n1(im); in2 = idm2n2(im);
  tg = eye(12);
  tg(1, 6) = -yr(in1);
  tg(2, 6) = xr(in1);
  tg(7, 12) = -yr(in2);
  tg(8, 12) = xr(in2);
  ke = tg' * ke * tg;

  % 軸力回復用2x12変換行列
  t = cxl(im, :);
  tt = zeros(2, 12);
  tt(1, 1:3) = t;
  tt(2, 7:9) = t;
  tt(1, 6) = t(1)*(-yr(in1)) + t(2)*xr(in1);
  tt(2, 12) = t(1)*(-yr(in2)) + t(2)*xr(in2);

  br_stif(idx).im = im;
  br_stif(idx).ke = ke;
  br_stif(idx).tt = tt;
  br_stif(idx).kn = kn_i;
  br_stif(idx).ndi = [idn2df(in1, :) idn2df(in2, :)];
  br_stif(idx).is_tb = is_tb(im);
end

return
end
