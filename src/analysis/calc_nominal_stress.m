function [stn, stcn] = calc_nominal_stress(...
  dfn, Mc, A, Asy, Asz, Aw, Zy, Zz, Zyf, Zyc, mtype, idnm2m)
% 応力から応力度を計算する

% 計算の準備
[nmn, ~, nlc] = size(dfn);

% 前処理
Asz(mtype==PRM.GIRDER) = Aw(mtype==PRM.GIRDER);
Zz(mtype==PRM.BRACE) = 1.d-6;

% 移し替え
idnm2m = idnm2m(:,1);
Mc = Mc(idnm2m,:);
A = A(idnm2m);
Asy = Asy(idnm2m);
Asz = Asz(idnm2m);
Zy = Zy(idnm2m);
Zz = Zz(idnm2m);
Zyf = Zyf(idnm2m);
Zyc = Zyc(idnm2m);
mtype = mtype(idnm2m);

% 応力度の計算
stn = zeros(nmn,12,nlc);
stcn = zeros(nmn,nlc);
for ilc = 1:nlc
  stn(:,1,ilc) = dfn(:,1,ilc)./A;
  stn(:,2,ilc) = dfn(:,2,ilc)./Asy;
  stn(:,3,ilc) = dfn(:,3,ilc)./Asz;
  stn(:,6,ilc) = dfn(:,6,ilc)./Zz;
  stn(:,7,ilc) = dfn(:,7,ilc)./A;
  stn(:,8,ilc) = dfn(:,8,ilc)./Asy;
  stn(:,9,ilc) = dfn(:,9,ilc)./Asz;
  stn(:,12,ilc) = dfn(:,12,ilc)./Zz;
  for inm = 1:nmn
    switch mtype(inm)
      case PRM.GIRDER
        stn(inm,5,ilc) = dfn(inm,5,ilc)/Zyf(inm);
        stn(inm,11,ilc) = dfn(inm,11,ilc)/Zyf(inm);
        stcn(inm,ilc) = Mc(inm,ilc)/Zyc(inm);
      case PRM.COLUMN
        stn(inm,5,ilc) = dfn(inm,5,ilc)/Zy(inm);
        stn(inm,11,ilc) = dfn(inm,11,ilc)/Zy(inm);
    end
  end
end
return
end
