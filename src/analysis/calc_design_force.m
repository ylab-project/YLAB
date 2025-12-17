function dfn0 = calc_design_force(...
  dfm0, Mc0, rvec0, lcdir, idmc2m, idmg2m, lmn, lf, nominal_property)
% 設計応力の計算

% 定数
nlc = length(lcdir);
nm = size(dfm0,1);
nnm = size(nominal_property.mtype,1);

% 配列
% lfcx = lf.columnx;
% lfcy = lf.columny;
ntype = nominal_property.ntype;
% mtype = nominal_property.mtype;
idnm2m = nominal_property.idme;
% dfn0 = zeros(nnm,12,nlc);

% 移し替え
dfn0 = dfm0(idnm2m(:,1),:,:);

% 名目部材の処理
for inm = 1:nnm

  % 通常部材はスキップ
  if ntype(inm)==PRM.NOMINAL_NORMAL_MEMBER
    continue
  end

  % 上下端部材番号
  ncol = nnz(idnm2m(inm,:));
  imb = idnm2m(inm,1);
  imt = idnm2m(inm,ncol);

  % 設計応力の対象成分
  ifb = false(1,12);
  ift = false(1,12);
  switch ntype(inm)
    case PRM.NOMINAL_MULTI_MEMBER
      % --- 一本部材 ---
      % 軸力
      ifb(1) = true;
      ift(7) = true;
      % せん断力
      ifb([2 3]) = true;
      ift([8 9]) = true;
      % 曲げ
      ifb(4:6) = true;
      ift(10:12) = true;
    case PRM.NOMINAL_MULTI_COLUMN_BRACE
      % --- ブレース付柱 ---
      % 軸力
      ift([1 7]) = true;
      % せん断力
      ift([2 3 8 9]) = true;
      % 曲げ
      ifb(4:6) = true;
      ift(10:12) = true;
    otherwise
      error('指定外の名目部材です')
  end

  % 設計応力の移し替え
  dfn0(inm,ifb,:) = dfm0(imb,ifb,:);
  dfn0(inm,ift,:) = dfm0(imt,ift,:);
end
return
end

