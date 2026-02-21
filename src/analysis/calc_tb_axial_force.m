function N = calc_tb_axial_force( ...
  tmat, kn, ndi, dvec_ilc)
%calc_tb_axial_force - 引張ブレースの軸力計算
%
%   N = calc_tb_axial_force(tmat, kn, ndi, ...
%     dvec_ilc) は、
%   引張ブレースの軸力を計算する。
%
%   入力引数:
%     tmat - 変換行列 [12x12]
%     kn - 軸剛性 EA/L
%     ndi - 自由度番号 [1x12]
%     dvec_ilc - 変位ベクトル [ndf×1]
%
%   出力引数:
%     N - 軸力（正=引張、負=圧縮）

d_local = tmat * dvec_ilc(ndi);
N = kn * (d_local(7) - d_local(1));

return
end
