function fbn4 = calc_nominal_fb(msdim_n, Cn, ...
  clam_n, ft_n, stype_n, lbn, options)
%calc_nominal_fb - 名目梁の4位置でfbを算定
%
%   入力引数:
%     msdim_n [nng×4] - 断面寸法(H,B,tw,tf)
%     Cn      [nng×4×nlc] - 名目梁4位置のC
%     clam_n  [nng×1] - 限界細長比
%     ft_n    [nng×2] - 許容引張応力度[長期,短期]
%     stype_n [nng×1] - 断面タイプ
%     lbn     [nng×4] - 名目梁4位置のlb
%     options - オプション構造体
%
%   出力引数:
%     fbn4 [nng×4×nlc] - 名目梁4位置のfb

nng = size(lbn, 1);
nlc = size(Cn, 3);
fbn4 = zeros(nng, 4, nlc);

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
    lbi = lbn(ing, :);
    C1 = Cn(ing, :, jlc);
    siy = sqrt((tf*B^3/12) ...
      / (tf*B + (H/6-tf)*tw));
    fb1 = (1 - 0.4*(lbi/siy).^2 ...
      ./ (C1*clam_n(ing)^2)) .* Ft;
    fb2 = 89000 ./ (lbi*H/(tf*B));
    if jlc > 1
      fb2 = fb2 * 1.5;
    end
    fb_ = max(fb1, fb2);
    fb_(fb_ > Ft) = Ft;
    fbn4(ing, :, jlc) = fb_;
  end
end

return
end
