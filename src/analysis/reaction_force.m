function rvec = reaction_force(ilcset, dnode, frvec, rvec, sks, ...
  idn2df, idsup2n, issupfixed)
%reaction_force - 支点ばね力を考慮した反力を算出
%
%   rvec = reaction_force(ilcset, dnode, frvec, rvec, sks, ...
%     idn2df, idsup2n, issupfixed) は、指定荷重ケースの節点外力から
%   支点ばね力を差し引き、拘束自由度の反力を更新する。
%
%   入力引数:
%     ilcset - 更新する荷重ケース番号
%     dnode - 節点変位 [nnode×6×nlc]
%     frvec - 補正済み節点外力 [ndf×nlc]
%     rvec - 更新前の支点反力 [6*nsup×nlc]
%     sks - 支点ばね対角値 [6*nsup×nlc]
%     idn2df - 節点→自由度変換 [nnode×6]
%     idsup2n - 支点→節点変換 [nsup×1]
%     issupfixed - 支点拘束 [nsup×6]
%
%   出力引数:
%     rvec - 更新後の支点反力 [6*nsup×nlc]

nsup = length(idsup2n);

for ilc = ilcset
  for isup = 1:nsup
    in = idsup2n(isup);
    idf = idn2df(in, :);
    m1 = 6 * (isup - 1);

    for k = 1:6
      if issupfixed(isup, k)
        mk = m1 + k;
        rvec(mk, ilc) = frvec(idf(k), ilc) - sks(mk, ilc) ...
          * dnode(in, k, ilc);
      end
    end
  end
end

return
end
