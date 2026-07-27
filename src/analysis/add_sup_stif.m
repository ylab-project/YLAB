function [ks, sks] = add_sup_stif(ks, xr, yr, idsup2n, ...
  isfixedsup, isuplifted, idn2df)
%add_sup_stif - 支点ばね剛性を全体剛性行列に加算する
%
%   [ks, sks] = add_sup_stif(ks, xr, yr, idsup2n, isfixedsup, ...
%     isuplifted, idn2df) は、各支点の拘束自由度に SS7 マニュアル
%   §5.2.6 準拠の絶対値ばね剛性を付与し、剛床オフセットを考慮した
%   座標変換を行って全体剛性行列 ks に重ね合わせる。浮き上がり時は
%   鉛直ばねを完全解除する。単位系は N, mm
%   （回転は N*mm/rad）。
%
%   入力引数:
%     ks         - 全体剛性行列（スカイライン格納） [ndof×nband]
%     xr, yr     - 節点から剛床基準点までのオフセット [nnode×1]
%     idsup2n    - 支点番号 -> 節点番号の対応 [nsup×1]
%     isfixedsup - 拘束フラグ [nsup×6]（k=1-6: UX,UY,UZ,RX,RY,RZ）
%     isuplifted - 浮き上がり状態フラグ [nsup×nlc]（空なら全非浮上）
%     idn2df     - 節点の自由度番号 [nnode×6]
%
%   出力引数:
%     ks  - 支点ばねを加算した全体剛性行列（nlc==1 時のみ更新）
%     sks - 各支点の対角ばね値 [6*nsup×nlc]（非拘束自由度は 0）
%
%   備考:
%     - SS7 絶対値: 並進水平 1e10 N/mm, 並進鉛直 1e13 N/mm,
%       回転 1e18 N*mm/rad。
%     - 浮き上がり支点の鉛直ばねは完全解除する。
%     - nlc>1 の場合は sks のみ返し ks への加算は行わない。

nsup = length(idsup2n);
ns6 = nsup*6;
nlc = size(isuplifted,2);

if isempty(isuplifted)
  isuplifted = false(1,nsup);
end

ss7_spring = [1.d10 1.d10 1.d13 1.d18 1.d18 1.d18];
sks = zeros(ns6, nlc);
for ilc = 1:nlc
  for isup = 1:nsup
    m1 = 6 * (isup - 1);
    for k = 1:6
      if ~isfixedsup(isup, k)
        continue
      end
      if isuplifted(isup, ilc) && k == 3
        continue
      end
      sks(m1 + k, ilc) = ss7_spring(k);
    end
  end
end

if (nlc==1)
  for isup = 1:nsup
    in = idsup2n(isup);
    idf = idn2df(in,:);
    m1 = 6*(isup-1);

    % 剛床オフセット（xr, yr）を反映する座標変換行列
    tg = eye(6);
    tg(1,6) = -yr(in,1);
    tg(2,6) = xr(in,1);
    sss = sks(m1+1:m1+6,ilc);
    skse = diag(sss);
    skse = tg'*skse*tg;

    % 上三角バンド格納への重ね合わせ
    for i = 1:6
      for j = 1:6
        k = idf(j)-idf(i);
        if k>=0
          k = k+1;
          ks(idf(i),k) = ks(idf(i),k)+skse(i,j);
        end
      end
    end
  end
end
return
end
