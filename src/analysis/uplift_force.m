function frvec = uplift_force(idnode2df, idsup2node, ...
  issupfixed, rvec, fvec, is_uplifted)
%uplift_force - 浮き上がり支点の長期反力を地震時外力へ反映
%
%   frvec = uplift_force(idnode2df, idsup2node, issupfixed, ...
%     rvec, fvec, is_uplifted) は、浮き上がり支点の長期鉛直反力を
%   地震時の鉛直節点外力へ重ね合わせ、補正後の外力を返す。
%
%   入力引数:
%     idnode2df - 節点→自由度変換 [nnode×6]
%     idsup2node - 支点→節点変換 [nsup×1]
%     issupfixed - 支点拘束 [nsup×6]
%     rvec - 支点反力 [6*nsup×nlc]
%     fvec - 補正前の節点外力 [ndf×nlc]
%     is_uplifted - 支点浮き上がり状態 [nsup×nlc]
%
%   出力引数:
%     frvec - 補正後の節点外力 [ndf×nlc]
%
%   備考:
%     - 長期ケースは1列目、地震ケースは2列目以降とする。

nlc = size(fvec, 2);
nsup = size(idsup2node, 1);

frvec = fvec;
for isj = 1:nsup
  % 自由境界をスキップ
  if ~issupfixed(isj, 3)
    continue
  end

  ijsup = idsup2node(isj);
  ijf = idnode2df(ijsup, 3);
  ir = (isj - 1) * 6 + 3;
  for ilc = 2:nlc
    if is_uplifted(isj, ilc)
      frvec(ijf, ilc) = frvec(ijf, ilc) - rvec(ir, 1);
    end
  end
end

return
end
