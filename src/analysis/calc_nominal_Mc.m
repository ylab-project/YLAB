function Mcn0 = calc_nominal_Mc(rs0, M0, Mc0, idmeg, ...
  idmg2m, idnmg2nm, lm, lf, kbrace_corr)
%calc_nominal_Mc - 名目部材レベルの中央Mを算出
%
%   Mcn0 = calc_nominal_Mc(rs0, M0, Mc0, idmeg, idmg2m, idnmg2nm,
%   lm, lf, kbrace_corr) は、名目梁の内法中央（フェイス間中央）
%   位置 M をケース別に算出し、名目部材レベル [nnm×1×nlc] で
%   返す。G+P（ilc=1）は分布荷重あり→放物線補間、地震（ilc>1）
%   は分布荷重なし→線形補間で中央位置の M を求める。
%   左右フェイス長が等しい通常節点では要素中央 L/2 と一致する。
%   Kブレース分割梁では、MID側せん断補正を中央断面まで積分する。
%   符号規約は calc_member_force の Mc と同一（Mc = -M(xc)）。
%
%   入力引数:
%     rs0          [nme×12×nlc] - 部材応力（ケース別）
%     M0           [nme×1] - 付加曲げ＋自重モーメント
%     Mc0          [nme×nlc] - 部材中央M（ケース別）
%     idmeg        [nng×nsub] - 名目梁→sub梁
%     idmg2m       [nmeg×1] - 梁→部材インデックス
%     idnmg2nm     [nng×1] - 名目梁→名目部材
%     lm           [nme×1] - 部材長
%     lf           構造体 - フェイス長
%     kbrace_corr  MID側せん断補正情報（任意）
%
%   出力引数:
%     Mcn0 [nnm×1×nlc] - 名目部材中央M

if nargin < 9
  kbrace_corr = [];
end
has_kbrace_corr = isstruct(kbrace_corr);
has_kbrace_corr = has_kbrace_corr && isfield(kbrace_corr, 'dq');
has_kbrace_corr = has_kbrace_corr && isfield(kbrace_corr, 'mid_end');

nlc = size(rs0, 3);
nnm = size(Mc0, 1);

% 初期値: Mc0 を [nnm×1×nlc] に reshape
Mcn0 = reshape(Mc0, nnm, 1, nlc);

% 名目梁ループ
nng = size(idmeg, 1);
for ing = 1:nng
  igs = idmeg(ing,:);
  igs(igs==0) = [];

  % 名目部材番号
  inm = idnmg2nm(ing);

  % sub 部材情報
  ig0 = igs(1);
  im_igs = idmg2m(igs);
  sub_lm = lm(im_igs);
  sub_x0 = [0; cumsum(sub_lm(1:end-1))];
  lnom = sum(sub_lm);

  % 内法スパン中央
  lf_l = lf.girder(ig0, 1);
  lf_r = lf.girder(igs(end), 2);
  xc = lf_l + (lnom - lf_l - lf_r) / 2;
  ksub = find(sub_x0 <= xc, 1, 'last');
  t = xc - sub_x0(ksub);
  lk = sub_lm(ksub);
  im = im_igs(ksub);

  % ケース別に中央Mを算出
  for ilc = 1:nlc
    Mlk = -rs0(im, 5, ilc);
    Mrk = rs0(im, 11, ilc);
    % G+P(ilc=1)は分布荷重あり→放物線補間
    % 地震(ilc>1)は分布荷重なし→線形補間
    if ilc == 1
      M0k = M0(im, 1);
    else
      M0k = 0;
    end
    Mx = 4*M0k*t^2/lk^2 + (Mrk-Mlk-4*M0k)*t/lk + Mlk;
    if has_kbrace_corr
      Mx = add_kbrace_mid_shear_moment(Mx, kbrace_corr, im, ilc, t, lk);
    end
    % 符号反転: Mc = -M(L/2) の規約に合わせる
    Mcn0(inm, 1, ilc) = -Mx;
  end
end

return
end

function Mx = add_kbrace_mid_shear_moment(Mx, kbrace_corr, im, ilc, t, lk)
%add_kbrace_mid_shear_moment - MID側せん断補正によるM増分を加算

mid_end = kbrace_corr.mid_end(im);
if mid_end == 0
  return
end

dq = kbrace_corr.dq(im, ilc);
if dq == 0
  return
end

if mid_end == 1
  dx_mid = t;
else
  dx_mid = lk - t;
end
Mx = Mx + dq * dx_mid;

return
end
