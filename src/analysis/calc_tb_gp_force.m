function f = calc_tb_gp_force(br_stif, id_tb, dvec_gp, ...
  iscompressed_ilc, iscompressed_gp)
%calc_tb_gp_force - 圧縮TBのG+P外力計算
%
%   f = calc_tb_gp_force(br_stif, id_tb,
%     dvec_gp, iscompressed_ilc,
%     iscompressed_gp) は、
%   地震ケースで圧縮除去されたブレースの
%   G+P節点力を外力として返す。
%
%   入力引数:
%     br_stif - ブレース構造体配列
%     id_tb - TBインデックス [1×ntb]
%     dvec_gp - G+P変位ベクトル [ndf×1]
%     iscompressed_ilc - 当該ケース圧縮状態 [ntb×1]
%     iscompressed_gp - G+P圧縮状態 [ntb×1]
%
%   出力引数:
%     f - G+P外力ベクトル [ndf×1]
%
%   備考:
%     - 当該ケースで圧縮かつG+P非圧縮のTBのみ
%       G+P節点力 (ke * dvec_gp) を加算する
%     - G+P圧縮済TBはG+P力=0のため対象外

ndf = length(dvec_gp);
f = zeros(ndf, 1);
ntb_ = length(id_tb);

for itb = 1:ntb_
  if ~iscompressed_ilc(itb)
    continue
  end
  if iscompressed_gp(itb)
    continue
  end
  idx_ = id_tb(itb);
  ndi_ = br_stif(idx_).ndi;
  f(ndi_) = f(ndi_) + br_stif(idx_).ke * dvec_gp(ndi_);
end

return
end
