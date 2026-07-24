function fc = calc_fc(lamy, lamz, clam, Fm)
%calc_fc - 細長比から許容圧縮応力度を計算する
%
%   fc = calc_fc(lamy, lamz, clam, Fm) は、部材の方向別細長比と
%   限界細長比から許容圧縮応力度を計算する。
%
%   入力引数:
%     lamy - X方向細長比 [nme×1]
%     lamz - Y方向細長比 [nme×3]
%     clam - 限界細長比 [nme×1]
%     Fm   - 基準強度 [nme×1]
%
%   出力引数:
%     fc - 許容圧縮応力度 [nme×3×5]

nme = length(Fm);
nlc = 5;
fc = zeros(nme, 3, nlc);

for im = 1:nme
  for j = 1:3
    lambda = max(lamy(im), lamz(im, j));
    if lambda <= clam(im)
      nu = 3/2 + 2/3*(lambda/clam(im))^2;
      fc(im, j, 1) = Fm(im)/nu*(1.0 - 0.4*(lambda/clam(im))^2);
    else
      fc(im, j, 1) = 0.277*Fm(im)/(lambda/clam(im))^2;
    end
  end
end

% 短期許容応力度（長期の1.5倍）
for ilc = 2:nlc
  fc(:, :, ilc) = fc(:, :, 1)*1.5;
end

return
end
