function [ks, sks] = add_sup_stif(...
  ks, xr, yr, idsup2n, isfixedsup, isuplifted, idn2df)

% 共通定数
nsup = length(idsup2n);
ns6 = nsup*6;

% 定数
nlc = size(isuplifted,2);

% 初期化
if isempty(isuplifted)
  isuplifted = false(1,nsup);
end

% 支点ばねの計算
sks = zeros(ns6, nlc);
for ilc = 1:nlc
  for isup = 1:nsup
    in = idsup2n(isup);
    idf = idn2df(in,:);
    m1 = 6*(isup-1);
    for k = 1:6
      if isfixedsup(isup,k)
        if (isuplifted(isup,ilc) && k==3)
          coef = 1.d-6;
        else
          coef = PRM.RIGID_COEF;
        end
        mk = m1+k;
        sks(mk,ilc) = ks(idf(k),1)*coef;
      end
    end
  end
end

% 支点ばねの加算
if (nlc==1)
  for isup = 1:nsup
    in = idsup2n(isup);
    idf = idn2df(in,:);
    m1 = 6*(isup-1);

    % 剛床を考慮した変換
    tg = eye(6);
    tg(1,6) = -yr(in,1);
    tg(2,6) = xr(in,1);
    sss = sks(m1+1:m1+6,ilc);
    skse = diag(sss);
    skse = tg'*skse*tg;

    % 重ね合わせ
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
