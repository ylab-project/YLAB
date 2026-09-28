function [fbn4, is_fb1_4] = calc_nominal_fb(msdim_n, Cn, ...
  clam_n, ft_n, stype_n, lbn, options)
%calc_nominal_fb - 名目部材の検定位置ごとにH形鋼の強軸まわりのfbを算定
%
%   [fbn4, is_fb1_4] = calc_nominal_fb(msdim_n, Cn, clam_n, ft_n,
%   stype_n, lbn, options) は、名目部材の各検定位置について、H形鋼
%   （梁のWFS、柱のCWFS・CWFSI）の強軸まわりの許容曲げ応力度を
%   横座屈式（計算編 式2.13～2.15）で算定する。H形鋼以外と横座屈を
%   考慮しない指定では ft を返す。位置数は lbn の列数に従う（名目梁は
%   左端・右端・中央L・中央Rの4位置）。
%
%   入力引数:
%     msdim_n [nn×5] - 断面寸法(H,B,tw,tf,r)
%     Cn      [nn×npos×nlc] - 位置別の修正係数C
%     clam_n  [nn×1] - 限界細長比
%     ft_n    [nn×2] - 許容引張応力度[長期,短期]
%     stype_n [nn×1] - 断面タイプ
%     lbn     [nn×npos] - 位置別の横座屈長さ（圧縮フランジ支点間距離）
%     options - オプション構造体
%
%   出力引数:
%     fbn4     [nn×npos×nlc] - 位置別のfb
%     is_fb1_4 [nn×npos×nlc] - fb1式でfbが決定した位置
%
%   備考:
%     siyはSS7マニュアル準拠で「圧縮フランジ＋ウェブ1/6 のT形断面」
%     の弱軸断面二次半径として算出する（r込みのA,Izを使用）。

[nn, npos] = size(lbn);
nlc = size(Cn, 3);
fbn4 = zeros(nn, npos, nlc);
is_fb1_4 = false(nn, npos, nlc);

% H形断面のr込みA,Izを一括取得
stype_n = stype_n(:);
is_h = stype_n == PRM.WFS | stype_n == PRM.CWFS | stype_n == PRM.CWFSI;
A_h = zeros(nn, 1);
Iz_h = zeros(nn, 1);
if any(is_h)
  props = calc_prop_wfs(msdim_n(is_h, :));
  A_h(is_h) = props(:, 1);
  Iz_h(is_h) = props(:, 5);
end

for ing = 1:nn
  for jlc = 1:nlc
    if jlc == 1
      Ft = ft_n(ing, 1);
    else
      Ft = ft_n(ing, 2);
    end

    if ~options.consider_lateral_torsional_buckling || ~is_h(ing)
      fbn4(ing, :, jlc) = Ft;
      continue
    end

    H = msdim_n(ing, 1);
    B = msdim_n(ing, 2);
    tw = msdim_n(ing, 3);
    tf = msdim_n(ing, 4);
    Az = A_h(ing);
    Iz = Iz_h(ing);
    lbi = lbn(ing, :);
    C1 = Cn(ing, :, jlc);
    I16 = Iz/2 - (H*tw^3/12)/3;
    A16 = Az/2 - (H*tw)/3;
    siy = sqrt(I16/A16);
    fb1 = (1 - 0.4*(lbi/siy).^2 ./ (C1*clam_n(ing)^2)) .* Ft;
    fb2 = 89000 ./ (lbi*H/(tf*B));
    if jlc > 1
      fb2 = fb2 * 1.5;
    end
    fb_raw = max(fb1, fb2);
    tol_fb = 1e-8;
    is_fb1 = fb1 >= fb2 - tol_fb & fb_raw < Ft - tol_fb;
    fb_ = fb_raw;
    fb_(fb_ > Ft) = Ft;
    fbn4(ing, :, jlc) = fb_;
    is_fb1_4(ing, :, jlc) = is_fb1;
  end
end

return
end
