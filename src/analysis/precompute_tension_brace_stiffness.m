function tb_stif = precompute_tension_brace_stiffness( ...
  A, Iy, Iz, JJ, cxl, cyl, lm, Em, prm, ...
  xr, yr, idn2df, idm2n1, idm2n2, ...
  mtype, stype, idm2s, flag, ...
  is_tension_only)
%precompute_tension_brace_stiffness - 引張ブレース剛性の事前計算
%
%   tb_stif = precompute_tension_brace_stiffness(...)
%   は、引張ブレース部材の全体剛性マトリクスへの寄与を
%   事前計算し、収束ループ内での剛性減算に使用する
%   構造体配列を返す。
%
%   入力引数:
%     A - 断面積 [nme×1]
%     Iy, Iz - 断面二次モーメント [nme×1]
%     JJ - ねじり定数 [nme×1]
%     cxl, cyl - 部材座標系方向余弦 [nme×3]
%     lm - 部材長 [nme×1]
%     Em - ヤング係数 [nme×1]
%     prm - ポアソン比 [nme×1]
%     xr, yr - 相対座標 [nnode×1]
%     idn2df - 節点-自由度変換 [nnode×6]
%     idm2n1, idm2n2 - 部材端節点 [nme×1]
%     mtype - 部材種別 [nme×1]
%     stype - 断面種別 [nsec×1]
%     idm2s - 部材-断面変換 [nme×1]
%     flag - 解析フラグ
%     is_tension_only - λe判定による引張のみ [nme×1]
%
%   出力引数:
%     tb_stif - 構造体配列 [ntb×1]
%       im   - 全体部材番号
%       ke   - 要素剛性行列（組立座標系）[12×12]
%       ndi  - 自由度番号 [1×12]
%       tmat - 変換行列（dvec→局所変位）[12×12]
%       kn   - 軸剛性 EA/L

% 引張ブレース部材の特定（TB + λe判定鋼材 + 水平ブレース引張のみ）
is_tb = ((mtype == PRM.BRACE) ...
  & (stype(idm2s) == PRM.TB ...
  | is_tension_only)) ...
  | ((mtype == PRM.HORIZONTAL_BRACE) ...
  & is_tension_only);
id_tb = find(is_tb);
ntb = length(id_tb);

if ntb == 0
  tb_stif = struct( ...
    'im', {}, 'ke', {}, 'ndi', {}, ...
    'tmat', {}, 'kn', {});
  return
end

% 方向余弦
czl = cross(cxl, cyl, 2);
z = zeros(3, 3);

% 構造体配列の初期化
tb_stif(ntb) = struct( ...
  'im', 0, 'ke', zeros(12), ...
  'ndi', zeros(1, 12), ...
  'tmat', zeros(12), 'kn', 0);

for idx = 1:ntb
  im = id_tb(idx);

  % 部材特性（ブレース: Asy=Asz=A, 全端ピン）
  li = lm(im);
  Ai = A(im);
  Iyi = Iy(im);
  Izi = Iz(im);
  Ji = JJ(im);
  Ei = Em(im);
  pri = prm(im);
  jointi = PRM.PIN * ones(1, 4);

  % 要素剛性行列（局所座標系）
  ke = stif_beam_matrix( ...
    li, Ai, Ai, Ai, Iyi, Izi, Ji, ...
    Ei, pri, [0 0], [0 0], ...
    jointi, [], flag);

  % 局所系→全体系変換
  t = [cxl(im,:); cyl(im,:); czl(im,:)];
  tm = [t z z z; z t z z; ...
    z z t z; z z z t];
  ke = tm' * ke * tm;

  % 剛床変換
  in1 = idm2n1(im);
  in2 = idm2n2(im);
  tg = eye(12);
  tg(1, 6) = -yr(in1);
  tg(2, 6) = xr(in1);
  tg(7, 12) = -yr(in2);
  tg(8, 12) = xr(in2);
  ke = tg' * ke * tg;

  % 保存
  tb_stif(idx).im = im;
  tb_stif(idx).ke = ke;
  tb_stif(idx).ndi = ...
    [idn2df(in1, :) idn2df(in2, :)];
  tb_stif(idx).tmat = tm * tg;
  tb_stif(idx).kn = Ei * Ai / li;
end

return
end
