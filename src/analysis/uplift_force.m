function frvec = uplift_force(...
  idnode2df, idme2j1, idsup2node, issupfixed, ...
  rvec, fvec, is_uplifted)
%UPLIFT_FORCE この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
nlc = size(fvec, 2);
% nm = length(idme2j1);
nsj = size(idsup2node, 1);

% 反力（長期軸力）を節点力に変換
frvec = fvec;
for isj=1:nsj
  % 自由境界をスキップ
  if ~issupfixed(isj,3)
    continue
  end

  % 浮き上がり支点
  ijsup = idsup2node(isj);  % 支点の節点番号
  ijf = idnode2df(ijsup,3); % 支点Z方向の自由度番号
  for ilc=2:nlc
    if is_uplifted(isj, ilc)
      % frvec(ijf,ilc) = frvec(ijf,ilc)+rvec(ijf,1);
      ir = (isj-1)*6+3;
      frvec(ijf,ilc) = frvec(ijf,ilc)-rvec(ir,1);
    end
  end
end

return
end

