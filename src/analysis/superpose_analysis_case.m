function [rs, Mc, rvec, cgsrn] = superpose_analysis_case(...
  rs0, Mc0, rvec0, lcdir, stress_factor)
%superpose_analysis_case - 解析（荷重）ケースの重ね合わせ
%
%   [rs, Mc, rvec, cgsrn] = superpose_analysis_case(rs0, Mc0,
%   rvec0, lcdir, stress_factor) は、長期ケースと地震時ケースを重ね
%   合わせ、短期の組合せ応力を求める。地震時応力には方向別に
%   stress_factor を乗じて割り増す。フェース補正は行わず、rs は
%   節点端ベースの応力として返す（フェース補正は df 側の責務）。
%
%   入力引数:
%     rs0 - ケース別の節点端部材応力 [nm×12×nlc]
%     Mc0 - ケース別の部材中央曲げ [nm×nlc]
%     rvec0 - ケース別の断面力ベクトル [ns6×nlc]
%     lcdir - 各ケースの方向コード（PRM.LT/EXP/EXN/EYP/EYN）[nlc×1]
%     stress_factor - 地震時設計応力の割増係数 [nm×1]
%
%   出力引数:
%     rs - 重ね合わせ後の節点端部材応力 [nm×12×nlc]
%     Mc - 重ね合わせ後の部材中央曲げ [nm×nlc]
%     rvec - 重ね合わせ後の断面力ベクトル [ns6×nlc]
%     cgsrn - 柱梁耐力比用の軸力（地震時は1.5倍）[nm×nlc]
%
%   備考:
%     - 第3次元のインデックスは方向コード（PRM.LT/EXP等）に対応
%     - C補正係数の算定もこの節点端Mを用いる（SS7整合）

% 定数
nlc = length(lcdir);
nm = size(rs0,1);

% 配列
rs = zeros(nm,12,nlc);
Mc = zeros(nm,nlc);
ns6 = size(rvec0,1);
rvec = zeros(ns6,nlc);
cgsrn = zeros(nm,nlc);

% 長期
for ilc = 1:nlc
  if lcdir(ilc)==PRM.LT
    rs(:,:,1) = rs0(:,:,ilc);
    Mc(:,1) = Mc0(:,ilc);
    rvec(:,1) = rvec0(:,1);
    cgsrn(:,1) = rs0(:,1,ilc);
  end
end

% 短期 = 長期＋地震時
for ilc = 1:nlc
  switch lcdir(ilc)
    case PRM.EXP
      id = PRM.EXP;
    case PRM.EXN
      id = PRM.EXN;
    case PRM.EYP
      id = PRM.EYP;
    case PRM.EYN
      id = PRM.EYN;
    otherwise
      continue
  end
  rs0_ = rs0(:,:,ilc);

  % フェース補正は行わない（df 側の責務）。rs は節点端ベース。
  % C補正係数算定もこの節点端Mを用いる（SS7整合）。

  % 設計応力割増
  for j=1:12
    rs0_(:,j) = rs0_(:,j).*stress_factor;
  end

  % 重ね合わせ
  rs(:,:,id) = rs0_(:,:)+rs(:,:,1);
  Mc(:,id) = Mc0(:,ilc)+Mc(:,1);
  rvec(:,id) = rvec(:,ilc)+rvec0(:,1);
  cgsrn(:,id) = 1.5*rs0(:,1,ilc)+rs0(:,1,1);
end
return
end
