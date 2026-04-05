function iscompressed_ilc = check_brace_compression_case( ...
  br_stif, id_tb, dvec, ilc, iscompressed_ilc, iscompressed_gp)
%check_brace_compression_case - TB圧縮判定（単一ケース）
%
%   iscompressed_ilc = check_brace_compression_case( ...
%     br_stif, id_tb, dvec, ilc, ...
%     iscompressed_ilc, iscompressed_gp) は、
%   指定荷重ケースのTB圧縮状態を更新する。
%
%   入力引数:
%     br_stif - ブレース構造体配列
%     id_tb - TBインデックス [1×ntb]
%     dvec - 変位ベクトル [ndf×nlc]
%     ilc - 対象荷重ケース番号
%     iscompressed_ilc - 現在の圧縮状態 [ntb×1]
%     iscompressed_gp - G+P圧縮状態 [ntb×1]
%       （ilc=1では空配列、ilc>=2で使用）
%
%   出力引数:
%     iscompressed_ilc - 更新後 [ntb×1]
%
%   備考:
%     - 一度圧縮と判定されたブレースは復帰しない
%     - ilc=1: N_long < 0 で圧縮判定
%     - ilc>=2: N_long + N_seis < 0 で圧縮判定
%       （G+P除去済みブレースの N_long は 0）

ntb = length(id_tb);

for itb = 1:ntb
  if iscompressed_ilc(itb)
    continue
  end
  idx_ = id_tb(itb);
  tt_ = br_stif(idx_).tt;
  kn_ = br_stif(idx_).kn;
  ndi_ = br_stif(idx_).ndi;
  if ilc == 1
    d_ = tt_ * dvec(ndi_, 1);
    N_long = kn_ * (d_(2) - d_(1));
    if N_long < 0
      iscompressed_ilc(itb) = true;
    end
  else
    if iscompressed_gp(itb)
      N_long = 0;
    else
      d_ = tt_ * dvec(ndi_, 1);
      N_long = kn_ * (d_(2) - d_(1));
    end
    d_ = tt_ * dvec(ndi_, ilc);
    N_seis = kn_ * (d_(2) - d_(1));
    if N_long + N_seis < 0
      iscompressed_ilc(itb) = true;
    end
  end
end

return
end
