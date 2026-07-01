function [stn, stcn] = calc_nominal_stress(dfn, Mc, A, Asc, ...
  Asy, Asz, Aw, Zy, Zz, Zyij, Zyc, secdim, stype, F, ...
  mtype, idnm2m)
%calc_nominal_stress - 応力から応力度を計算する
%
%   [stn, stcn] = calc_nominal_stress(dfn, Mc, A, Asc, Asy, Asz,
%     Aw, Zy, Zz, Zyij, Zyc, secdim, stype, F, mtype, idnm2m) は、
%     名目部材応力から許容応力度検定用の応力度を計算する。
%     幅厚比制限超過時の有効断面性能は内部で作成する。

% 計算の準備
[nmn, ~, nlc] = size(dfn);

% 応力度計算用の有効断面性能
[~, Asc, Asy, Asz, Aw, Zy, Zz] = calc_effective_stress_secprop(...
  A, Asc, Asy, Asz, Aw, Zy, Zz, secdim, stype, F);

% 前処理
Asz(mtype==PRM.GIRDER) = Aw(mtype==PRM.GIRDER);
Zz(mtype==PRM.BRACE) = 1.d-6;

% 移し替え（Mc は既に nnm 空間）
idnm2m = idnm2m(:,1);
Asc = Asc(idnm2m);
Asy = Asy(idnm2m);
Asz = Asz(idnm2m);
Zy = Zy(idnm2m);
Zz = Zz(idnm2m);
Zyij = Zyij(idnm2m);
Zyc = Zyc(idnm2m);
mtype = mtype(idnm2m);

% 応力度の計算
stn = zeros(nmn,12,nlc);
stcn = zeros(nmn,nlc);
for ilc = 1:nlc
  stn(:,1,ilc) = dfn(:,1,ilc)./Asc;   % σc i端（スカラップ考慮）
  stn(:,2,ilc) = dfn(:,2,ilc)./Asy;
  stn(:,3,ilc) = dfn(:,3,ilc)./Asz;
  stn(:,6,ilc) = dfn(:,6,ilc)./Zz;
  stn(:,7,ilc) = dfn(:,7,ilc)./Asc;   % σc j端（スカラップ考慮）
  stn(:,8,ilc) = dfn(:,8,ilc)./Asy;
  stn(:,9,ilc) = dfn(:,9,ilc)./Asz;
  stn(:,12,ilc) = dfn(:,12,ilc)./Zz;
  for inm = 1:nmn
    switch mtype(inm)
      case PRM.GIRDER
        stn(inm,5,ilc) = dfn(inm,5,ilc)/Zyij(inm);
        stn(inm,11,ilc) = dfn(inm,11,ilc)/Zyij(inm);
        stcn(inm,ilc) = Mc(inm,ilc)/Zyc(inm);
      case PRM.COLUMN
        stn(inm,5,ilc) = dfn(inm,5,ilc)/Zy(inm);
        stn(inm,11,ilc) = dfn(inm,11,ilc)/Zy(inm);
    end
  end
end

return
end
