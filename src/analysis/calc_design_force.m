function df0 = calc_design_force(...
  rs0, lcdir, idmc2m, idmg2m, lm, lf)
%calc_design_force - 部材応力rsから設計応力dfへの変換
%
%   フェイスモーメントの補正およびi端軸力の符号反転を行い、
%   設計応力df0（引張正）を返す。

% 定数
nlc = length(lcdir);

% 配列
lg = lm(idmg2m);
lc = lm(idmc2m);
lfg = lf.girder;

% i端軸力の符号反転（局所座標系の圧縮正→引張正）
df0 = rs0;
df0(:,1,:) = -df0(:,1,:);

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
  Mgi = df0(idmg2m,5,ilc);
  Mgj = df0(idmg2m,11,ilc);
  Mgfi = Mgi.*(lg-lfg(:,1))./lg-Mgj.*lfg(:,1)./lg;
  Mgfj = Mgj.*(lg-lfg(:,2))./lg-Mgi.*lfg(:,2)./lg;
  df0(idmg2m,5,ilc) = Mgfi;
  df0(idmg2m,11,ilc) = Mgfj;

  % 柱フェースモーメント（X）の計算（長期は節点位置）
  Mcxi = df0(idmc2m,5,ilc);
  Mcxj = df0(idmc2m,11,ilc);
  Mcxfi = Mcxi.*(lc-lfcm(:,1))./lc ...
    - Mcxj.*lfcm(:,1)./lc;
  Mcxfj = Mcxj.*(lc-lfcm(:,2))./lc ...
    - Mcxi.*lfcm(:,2)./lc;
  df0(idmc2m,5,ilc) = Mcxfi;
  df0(idmc2m,11,ilc) = Mcxfj;

  % 柱フェースモーメント（Y）の計算（長期は節点位置）
  Mcyi = df0(idmc2m,6,ilc);
  Mcyj = df0(idmc2m,12,ilc);
  Mcyfi = Mcyi.*(lc-lfcm(:,1))./lc ...
    - Mcyj.*lfcm(:,1)./lc;
  Mcyfj = Mcyj.*(lc-lfcm(:,2))./lc ...
    - Mcyi.*lfcm(:,2)./lc;
  df0(idmc2m,6,ilc) = Mcyfi;
  df0(idmc2m,12,ilc) = Mcyfj;
end

return
end
