function frvec_ilc = uplift_force_case( ...
  idn2df, idsup2n, isfixedsup, ...
  rvec, fvec_ilc, isuplifted_ilc)
%uplift_force_case - 浮き上がり外力補正（単一ケース）
%
%   frvec_ilc = uplift_force_case( ...
%     idn2df, idsup2n, isfixedsup, ...
%     rvec, fvec_ilc, isuplifted_ilc) は、
%   浮き上がり支点の長期反力を外力に変換する。
%
%   入力引数:
%     idn2df - 節点→自由度変換 [nnode×6]
%     idsup2n - 支点→節点変換 [nsup×1]
%     isfixedsup - 支点拘束 [nsup×6]
%     rvec - 反力ベクトル [ns6×nlc]
%     fvec_ilc - 外力ベクトル [ndf×1]
%     isuplifted_ilc - 浮き上がり [nsup×1]
%
%   出力引数:
%     frvec_ilc - 補正後外力 [ndf×1]

nsup = length(idsup2n);
frvec_ilc = fvec_ilc;
for isj = 1:nsup
  if ~isfixedsup(isj, 3)
    continue
  end
  if isuplifted_ilc(isj)
    ijsup = idsup2n(isj);
    ijf = idn2df(ijsup, 3);
    ir = (isj - 1) * 6 + 3;
    frvec_ilc(ijf) = ...
      frvec_ilc(ijf) - rvec(ir, 1);
  end
end

return
end
