function Ncn0 = calc_nominal_Nc(rs0, idmeg, idmg2m, idnmg2nm, nnm, lm, lf)
%calc_nominal_Nc - 名目部材レベルの中央Nを算出
%
%   分割梁の中央Nを内法スパン中央位置で線形補間し、
%   名目部材レベル [nnm×1×nlc] で返す。
%   単一sub梁はi端Nをそのまま使用する。
%
%   入力引数:
%     rs0      [nme×12×nlc] - 部材応力（ケース別）
%     idmeg    [nng×nsub] - 名目梁→sub梁
%     idmg2m   [nmeg×1] - 梁→部材インデックス
%     idnmg2nm [nng×1] - 名目梁→名目部材
%     nnm      スカラー - 名目部材数
%     lm       [nme×1] - 部材長
%     lf       構造体 - フェイス長
%
%   出力引数:
%     Ncn0 [nnm×1×nlc] - 名目部材中央N

nlc = size(rs0, 3);
Ncn0 = zeros(nnm, 1, nlc);

% 名目梁ループ
nng = size(idmeg, 1);
for ing = 1:nng
  igs = idmeg(ing,:);
  igs(igs==0) = [];

  % 名目部材番号
  inm = idnmg2nm(ing);
  nsub = length(igs);
  im_first = idmg2m(igs(1));

  if nsub <= 1
    % 単一sub梁: i端Nを使用
    Ncn0(inm, 1, :) = rs0(im_first, 1, :);
    continue
  end

  % 分割梁: 内法スパン中央で線形補間
  im_igs = idmg2m(igs);
  sub_lm = lm(im_igs);
  sub_x0 = [0; cumsum(sub_lm(1:end-1))];
  lnom = sum(sub_lm);

  ig0 = igs(1);
  lf_l = lf.girder(ig0, 1);
  lf_r = lf.girder(igs(end), 2);
  xc = lf_l + (lnom - lf_l - lf_r) / 2;
  ksub = find(sub_x0 <= xc, 1, 'last');
  t = xc - sub_x0(ksub);
  lk = sub_lm(ksub);

  % ケース別に中央Nを線形補間
  for ilc = 1:nlc
    Nlk = rs0(im_igs(ksub), 1, ilc);
    Nrk = rs0(im_igs(ksub), 7, ilc);
    Ncn0(inm, 1, ilc) = Nlk + (Nrk - Nlk) * t / lk;
  end
end

return
end
