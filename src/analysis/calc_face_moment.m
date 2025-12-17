function dfm0 = calc_face_moment(...
  rs0, lcdir, idmc2m, idmg2m, lm, lf, nominal_column)
% 解析（荷重）ケースの重ね合わせ

% 定数
nlc = length(lcdir);
% nm = size(rs0,1);
% nmg = size(idmg2m,1);

% 配列
lg = lm(idmg2m);
lc = lm(idmc2m);
lfg = lf.girder;

% 計算の準備
dfm0 = rs0;

% フェイスモーメントの計算
for ilc = 1:nlc
  % 長期をスキップ
  switch lcdir(ilc)
    case PRM.LT
      continue
    case PRM.EXP
      lfcm = lf.columnx;
    case PRM.EXN
      lfcm = lf.columnx;
    case PRM.EYP
      lfcm = lf.columny;
    case PRM.EYN
      lfcm = lf.columny;
  end

  % 梁フェースモーメントの計算（長期は節点位置）
  Mgi = dfm0(idmg2m,5,ilc);
  Mgj = dfm0(idmg2m,11,ilc);
  Mgfi = Mgi.*(lg-lfg(:,1))./lg-Mgj.*lfg(:,1)./lg;
  Mgfj = Mgj.*(lg-lfg(:,2))./lg-Mgi.*lfg(:,2)./lg;
  dfm0(idmg2m,5,ilc) = Mgfi;
  dfm0(idmg2m,11,ilc) = Mgfj;

  % 柱フェースモーメント（X）の計算（長期は節点位置）
  Mcxi = dfm0(idmc2m,5,ilc);
  Mcxj = dfm0(idmc2m,11,ilc);
  Mcxfi = Mcxi.*(lc-lfcm(:,1))./lc-Mcxj.*lfcm(:,1)./lc;
  Mcxfj = Mcxj.*(lc-lfcm(:,2))./lc-Mcxi.*lfcm(:,2)./lc;
  dfm0(idmc2m,5,ilc) = Mcxfi;
  dfm0(idmc2m,11,ilc) = Mcxfj;

  % 柱フェースモーメント（Y）の計算（長期は節点位置）
  Mcyi = dfm0(idmc2m,6,ilc);
  Mcyj = dfm0(idmc2m,12,ilc);
  Mcyfi = Mcyi.*(lc-lfcm(:,1))./lc-Mcyj.*lfcm(:,1)./lc;
  Mcyfj = Mcyj.*(lc-lfcm(:,2))./lc-Mcyi.*lfcm(:,2)./lc;
  dfm0(idmc2m,6,ilc) = Mcyfi;
  dfm0(idmc2m,12,ilc) = Mcyfj;
end

return
end