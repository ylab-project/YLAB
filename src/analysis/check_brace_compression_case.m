function iscompressed_ilc = ...
  check_brace_compression_case( ...
  tb_stif, dvec, ilc, ...
  iscompressed_ilc, iscompressed_gp)
%check_brace_compression_case - TB圧縮判定（単一ケース）
%
%   iscompressed_ilc = ...
%     check_brace_compression_case( ...
%     tb_stif, dvec, ilc, ...
%     iscompressed_ilc, iscompressed_gp) は、
%   指定荷重ケースのTB圧縮状態を更新する。
%
%   入力引数:
%     tb_stif - 引張ブレース構造体配列
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

ntb = length(tb_stif);

for idx = 1:ntb
  if iscompressed_ilc(idx)
    continue
  end
  if ilc == 1
    N_long = calc_tb_axial_force( ...
      tb_stif(idx).tmat, ...
      tb_stif(idx).kn, ...
      tb_stif(idx).ndi, dvec(:, 1));
    if N_long < 0
      iscompressed_ilc(idx) = true;
    end
  else
    if iscompressed_gp(idx)
      N_long = 0;
    else
      N_long = calc_tb_axial_force( ...
        tb_stif(idx).tmat, ...
        tb_stif(idx).kn, ...
        tb_stif(idx).ndi, dvec(:, 1));
    end
    N_seis = calc_tb_axial_force( ...
      tb_stif(idx).tmat, ...
      tb_stif(idx).kn, ...
      tb_stif(idx).ndi, dvec(:, ilc));
    if N_long + N_seis < 0
      iscompressed_ilc(idx) = true;
    end
  end
end

return
end
