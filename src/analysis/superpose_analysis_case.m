function [rs, Mc, rvec, cgsrn, dfm0] = superpose_analysis_case(...
  rs0, Mc0, rvec0, lcdir, idmc2m, idmg2m, lm, lf, stress_factor)
% 解析（荷重）ケースの重ね合わせ

% 定数
nlc = length(lcdir);
nm = size(rs0,1);
% nmg = size(idmg2m,1);

% 配列
lg = lm(idmg2m);
lc = lm(idmc2m);
lfg = lf.girder;
lfcx = lf.columnx;
lfcy = lf.columny;
rs = zeros(nm,12,nlc);
Mc = zeros(nm,nlc);
ns6 = size(rvec0,1);
rvec = zeros(ns6,nlc);
cgsrn = zeros(nm,nlc);
dfm0 = rs0;

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

  % 梁フェースモーメントの計算（長期は節点位置）
  Mgi = rs0_(idmg2m,5);
  Mgj = rs0_(idmg2m,11);
  Mgfi = Mgi.*(lg-lfg(:,1))./lg-Mgj.*lfg(:,1)./lg;
  Mgfj = Mgj.*(lg-lfg(:,2))./lg-Mgi.*lfg(:,2)./lg;
  rs0_(idmg2m,5) = Mgfi;
  rs0_(idmg2m,11) = Mgfj;

  % 柱フェースモーメント（X）の計算（長期は節点位置）
  Mcxi = rs0_(idmc2m,5);
  Mcxj = rs0_(idmc2m,11);
  Mcxfi = Mcxi.*(lc-lfcx(:,1))./lc-Mcxj.*lfcx(:,1)./lc;
  Mcxfj = Mcxj.*(lc-lfcx(:,2))./lc-Mcxi.*lfcx(:,2)./lc;
  rs0_(idmc2m,5) = Mcxfi;
  rs0_(idmc2m,11) = Mcxfj;

  % 柱フェースモーメント（Y）の計算（長期は節点位置）
  Mcyi = rs0_(idmc2m,6);
  Mcyj = rs0_(idmc2m,12);
  Mcyfi = Mcyi.*(lc-lfcy(:,1))./lc-Mcyj.*lfcy(:,1)./lc;
  Mcyfj = Mcyj.*(lc-lfcy(:,2))./lc-Mcyi.*lfcy(:,2)./lc;
  rs0_(idmc2m,6) = Mcyfi;
  rs0_(idmc2m,12) = Mcyfj;

  % 設計応力割増
  for j=1:12
    rs0_(:,j) = rs0_(:,j).*stress_factor;
  end

  % 重ね合わせ
  rs(:,:,id) = rs0_(:,:)+rs(:,:,1);
  Mc(:,id) = Mc0(:,ilc)+Mc(:,1);
  rvec(:,id) = rvec(:,ilc)+rvec0(:,1);
  cgsrn(:,id) = 1.5*rs0(:,1,ilc)+rs0(:,1,1);

  % 結果の保存
  dfm0(:,:,ilc) = rs0_;
end
return
end

