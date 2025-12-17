function [fc, lamy, lamz] = calc_fc(A, Iy, Iz, clam, mtype, stype, Fm, lkx, lky)
% Calculation of allowable compressive (fc) stress

% 定数
nme = length(mtype);
nlc = 5; % とりあえず

% fcの計算
fc = zeros(nme,3,nlc); % (左端,右端,中央)x荷重ケース
iy = sqrt(Iy./A);
iz = sqrt(Iz./A);
lamy = lkx./iy;
lamz = lky./iz;
lamy(mtype==PRM.BRACE) = 0;
lamz(mtype==PRM.BRACE) = 0;

for im = 1:nme
  % RC柱は座屈を考慮しない
  if mtype(im) == PRM.COLUMN && stype(im) == PRM.RCRS
    fc(im,1:3,1:nlc) = Fm(im)/1.5;  % 基準強度の許容応力度
    lamy(im) = 0;     % X方向細長比を0に
    lamz(im,:) = 0;   % Y方向細長比を0に（全補剛区間）
    continue
  end
  if mtype(im) == PRM.BRACE
    fc(im,1:3,1:nlc) = Fm(im)/1.5;
    continue
  end
  for j=1:3
    lambda = max(lamy(im), lamz(im,j));
    if lambda <= clam(im)
      nu = 3/2+2/3*(lambda/clam(im))^2;
      fc(im,j,1:nlc) = Fm(im)/nu*(1.0-0.4*(lambda/clam(im))^2);
    else
      fc(im,j,1:nlc) = 0.277*Fm(im)/(lambda/clam(im))^2;
    end
  end
end

% TODO: とりあえず
for ilc=2:nlc
  fc(:,:,ilc) = fc(:,:,1)*1.5;
end

return
end
