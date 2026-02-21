function iscompressed = check_brace_compression( ...
  tb_stif, dvec, nlc, iscompressed_prev)
%check_brace_compression - 引張ブレースの圧縮判定
%
%   iscompressed = check_brace_compression( ...
%     tb_stif, dvec, nlc, iscompressed_prev) は、
%   各引張ブレースの軸力を計算し、長期＋地震時の
%   合計が圧縮となるブレースを判定する。
%
%   入力引数:
%     tb_stif - 引張ブレース構造体配列
%     dvec - 変位ベクトル [ndf×nlc]
%     nlc - 荷重ケース数
%     iscompressed_prev - 前回の圧縮状態 [ntb×nlc]
%
%   出力引数:
%     iscompressed - 圧縮状態 [ntb×nlc]
%
%   備考:
%     - 一度圧縮と判定されたブレースは復帰しない

ntb = length(tb_stif);
iscompressed = iscompressed_prev;

for idx = 1:ntb
  ndi = tb_stif(idx).ndi;
  tmat = tb_stif(idx).tmat;
  kn = tb_stif(idx).kn;

  % 長期軸力（正=引張、負=圧縮）
  d_long = dvec(ndi, 1);
  d_local = tmat * d_long;
  N_long = kn * (d_local(7) - d_local(1));

  % 長期の圧縮判定
  if ~iscompressed(idx, 1) && N_long < 0
    iscompressed(idx, 1) = true;
  end

  % G+Pで除去済みブレースは弛み状態（実際の軸力=0）
  if iscompressed(idx, 1)
    N_long = 0;
  end

  for ilc = 2:nlc
    if iscompressed(idx, ilc)
      continue  % 圧縮除去済み
    end

    % 地震時軸力
    d_seis = dvec(ndi, ilc);
    d_local = tmat * d_seis;
    N_seis = kn * (d_local(7) - d_local(1));

    % 長期＋地震時の合計で判定
    if N_long + N_seis < 0
      iscompressed(idx, ilc) = true;
    end
  end
end

return
end
