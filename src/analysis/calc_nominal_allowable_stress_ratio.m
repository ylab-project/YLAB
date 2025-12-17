function [ration, fcn] = calc_nominal_allowable_stress_ratio(...
  st, stc, ftn, fcn, fbn, fsn, nmtype)
% Calculation of stress ratio

% 定数
[nnm, ~, nlc] = size(st);

% 初期化
ration = zeros(nnm,13,nlc);

for ilc = 1:nlc
  if (ilc==1)
    % 長期
    ilc_ = 1;
  else
    % 短期
    ilc_ = 2;
  end
  
  % 梁
  for inm = 1:nnm

    % Ni：引張／圧縮判定
    if st(inm,1,ilc)<=0
      fcn(inm,1,ilc) = ftn(inm,ilc_);
    end

    % Nj：引張／圧縮判定
    if st(inm,7,ilc)>=0
      fcn(inm,2,ilc) = ftn(inm,ilc_);
    end

    % 軸力度
    ration(inm,1,ilc) = st(inm,1,ilc)/fcn(inm,1,ilc);
    ration(inm,7,ilc) = st(inm,7,ilc)/fcn(inm,2,ilc);

    % ブレース省略
    if nmtype(inm)==PRM.BRACE
      continue
    end

    % せん断応力度
    ration(inm,2,ilc) = st(inm,2,ilc)/fsn(inm,ilc_);
    ration(inm,3,ilc) = st(inm,3,ilc)/fsn(inm,ilc_);
    ration(inm,8,ilc) = st(inm,8,ilc)/fsn(inm,ilc_);
    ration(inm,9,ilc) = st(inm,9,ilc)/fsn(inm,ilc_);

    % 曲げ応力度（強軸）
    ration(inm,5,ilc) = st(inm,5,ilc)/fbn(inm,1,ilc);
    ration(inm,11,ilc) = st(inm,11,ilc)/fbn(inm,2,ilc);

    % 曲げ応力度（弱軸） ※とりあえず
    ration(inm,6,ilc) = st(inm,6,ilc)/ftn(inm,ilc_);
    ration(inm,12,ilc) = st(inm,12,ilc)/ftn(inm,ilc_);

    switch nmtype(inm)
      case PRM.COLUMN
      case PRM.GIRDER
        ration(inm,13,ilc) = stc(inm,ilc)/fbn(inm,3,ilc);
    end
  end
end
return
end
