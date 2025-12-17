function dfn = superpose_design_force(dfn0, lcdir)
% 解析（荷重）ケースの重ね合わせ

% 定数
[nnm, ~, nlc] = size(dfn0);
% nm = size(rs0,1);
% nmg = size(idmg2m,1);

% 配列
% lg = lm(idmg2m);
% lc = lm(idmc2m);
% lfg = lf.girder;
% lfcx = lf.columnx;
% lfcy = lf.columny;
% rs = zeros(nm,12,nlc);
% Mc = zeros(nm,nlc);
% ns6 = size(rvec0,1);
% rvec = zeros(ns6,nlc);
% cgsrn = zeros(nm,nlc);
% dfm0 = rs0;
dfn = dfn0;

% 長期
for ilc = 1:nlc
  if lcdir(ilc)==PRM.LT
    dfn(:,:,1) = dfn0(:,:,ilc);
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
  
  % 重ね合わせ
  dfn(:,:,id) = dfn0(:,:,ilc)+dfn(:,:,1);
end
return
end
