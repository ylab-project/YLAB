function is_uplifted = check_uplift(idnode2jf, idsup2node, issupfixed, dvec)
%CHECK_FOUNDATION_UPLIFT この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
nlc = size(dvec,2);
nsup = size(issupfixed,1);

% 支点のz方向変位の抜き出し
suz = zeros(nsup,nlc);
for isj=1:nsup
  ijsup = idsup2node(isj);  % 支点の節点番号
  ijf = idnode2jf(ijsup,3); % 支点Z方向の自由度番号
  suz(isj,:) = dvec(ijf,:); % 支点のz方向変位
end

% 浮き上がり判定
is_uplifted = false(nsup, nlc);
suz(:,2:end) = suz(:,2:end)+suz(:,1);
for ilc=2:nlc
  % Z方向拘束かつZ方向変位が正の支点を探す
  is_uplifted(:,ilc) = issupfixed(:,3) & suz(:,ilc)>1.d-6;
end
return
end