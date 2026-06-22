function [fbn4, is_fb1_4] = calc_nominal_fb(msdim_n, Cn, ...
  clam_n, ft_n, stype_n, lbn, options)
%calc_nominal_fb - 名目梁の4位置でfbを算定
%
%   入力引数:
%     msdim_n [nng×5] - 断面寸法(H,B,tw,tf,r)
%     Cn      [nng×4×nlc] - 名目梁4位置のC
%     clam_n  [nng×1] - 限界細長比
%     ft_n    [nng×2] - 許容引張応力度[長期,短期]
%     stype_n [nng×1] - 断面タイプ
%     lbn     [nng×4] - 名目梁4位置のlb
%     options - オプション構造体
%
%   出力引数:
%     fbn4     [nng×4×nlc] - 名目梁4位置のfb
%     is_fb1_4 [nng×4×nlc] - fb1式でfbが決定した位置
%
%   備考:
%     siyはSS7マニュアル準拠で「圧縮フランジ＋ウェブ1/6 のT形断面」
%     の弱軸断面二次半径として算出する（r込みのA,Izを使用）。

nng = size(lbn, 1);
nlc = size(Cn, 3);
fbn4 = zeros(nng, 4, nlc);
is_fb1_4 = false(nng, 4, nlc);

% H形断面のr込みA,Izを一括取得
if ~isempty(msdim_n)
  sp_n = calc_prop_wfs(msdim_n);
else
  sp_n = zeros(0, 16);
end

for ing = 1:nng
  for jlc = 1:nlc
    if jlc == 1
      Ft = ft_n(ing, 1);
    else
      Ft = ft_n(ing, 2);
    end

    if ~options.consider_lateral_torsional_buckling
      fbn4(ing, :, jlc) = Ft;
      continue
    end
    if stype_n(ing) ~= PRM.WFS
      fbn4(ing, :, jlc) = Ft;
      continue
    end

    H = msdim_n(ing, 1);
    B = msdim_n(ing, 2);
    tw = msdim_n(ing, 3);
    tf = msdim_n(ing, 4);
    Az = sp_n(ing, 1);
    Iz = sp_n(ing, 5);
    lbi = lbn(ing, :);
    C1 = Cn(ing, :, jlc);
    I16 = Iz/2 - (H*tw^3/12)/3;
    A16 = Az/2 - (H*tw)/3;
    siy = sqrt(I16/A16);
    fb1 = (1 - 0.4*(lbi/siy).^2 ...
      ./ (C1*clam_n(ing)^2)) .* Ft;
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
