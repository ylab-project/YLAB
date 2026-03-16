function fcn4 = calc_nominal_fc(A_n, Iy_n, ...
  Iz_n, clam_n, Fm_n, lkx_n, lbn)
%calc_nominal_fc - 名目梁の4位置でfcを算定
%
%   入力引数:
%     A_n    [nng×1] - 断面積
%     Iy_n   [nng×1] - 断面二次モーメント(Y軸)
%     Iz_n   [nng×1] - 断面二次モーメント(Z軸)
%     clam_n [nng×1] - 限界細長比
%     Fm_n   [nng×1] - 基準強度
%     lkx_n  [nng×1] - X方向座屈長さ
%     lbn    [nng×4] - 名目梁4位置のlb(=lky)
%
%   出力引数:
%     fcn4 [nng×4×nlc] - 名目梁4位置のfc

% 定数
nng = size(lbn, 1);
nlc = 5;

% 細長比の計算
iy_n = sqrt(Iy_n ./ A_n);
iz_n = sqrt(Iz_n ./ A_n);
lamy_n = lkx_n ./ iy_n;

% fcの計算
fcn4 = zeros(nng, 4, nlc);
for ing = 1:nng
  for j = 1:4
    lamz_j = lbn(ing, j) / iz_n(ing);
    lambda = max(lamy_n(ing), lamz_j);
    if lambda <= clam_n(ing)
      nu = 3/2 ...
        + 2/3*(lambda/clam_n(ing))^2;
      fc1 = Fm_n(ing)/nu ...
        * (1.0 - 0.4 ...
        * (lambda/clam_n(ing))^2);
    else
      fc1 = 0.277*Fm_n(ing) ...
        / (lambda/clam_n(ing))^2;
    end
    fcn4(ing, j, 1) = fc1;
  end
end

% 短期
for ilc = 2:nlc
  fcn4(:,:,ilc) = fcn4(:,:,1) * 1.5;
end

return
end
