function rvec = reaction_force(ilcset, dnode, frvec, rvec, sks, ...
  xr, yr, idn2df, idsup2n, issupfixed)
%MEMBER_FORCE この関数の概要をここに記述
%   詳細説明をここに記述

% 共通定数
% ns6 = size(sks,1);
nsup = length(idsup2n);
% nlc = length(ilcset);
% ndf = com.ndf;

for ilc = ilcset
  for isup = 1:nsup
    % 支点の節点番号
    in = idsup2n(isup);  
    idf = idn2df(in,:);
    m1 = 6*(isup-1);

    % % 剛床を考慮した変換
    % tg = eye(6);
    % tg(1,6) = -yr(in,1);
    % tg(2,6) = xr(in,1);
    % sss = sks(m1+1:m1+6,ilc);
    % skse = diag(sss);
    % skse = tg'*skse*tg;
    % 
    % % 反力計算
    % fs = skse*dnode(in,:,ilc)';
    % rvec(m1+1:m1+6,ilc) = frvec(idf,ilc)-fs;

    % 反力計算
    for k = 1:6
      if issupfixed(isup,k)
        mk = m1+k;
        rvec(mk,ilc) = frvec(idf(k),ilc)-sks(mk,ilc)*dnode(in,k,ilc);
      end
    end
  end

end

return
end

