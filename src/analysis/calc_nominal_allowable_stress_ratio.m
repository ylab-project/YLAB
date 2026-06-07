function [ration, fcn, fbn] = calc_nominal_allowable_stress_ratio(...
  st, stc, ftn, fcn, fbn, fsn, nmtype, Ncn, A)
%calc_nominal_allowable_stress_ratio - 公称許容応力度比の算定

% 定数
[nnm, ~, nlc] = size(st);

% 初期化（15-18列はS柱組合せ応力度比 柱脚X/Y・柱頭X/Y）
ration = zeros(nnm,18,nlc);

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

    % Ni：引張時は fc,fb ともに ft に置換（引張正）
    if st(inm,1,ilc) > 0
      fcn(inm,1,ilc) = ftn(inm,ilc_);
      fbn(inm,1,ilc) = ftn(inm,ilc_);
    end

    % Nj：引張時は fc,fb ともに ft に置換（引張正）
    if st(inm,7,ilc) > 0
      fcn(inm,2,ilc) = ftn(inm,ilc_);
      fbn(inm,2,ilc) = ftn(inm,ilc_);
    end

    % 軸力度
    ration(inm,1,ilc) = st(inm,1,ilc)/fcn(inm,1,ilc);
    ration(inm,7,ilc) = st(inm,7,ilc)/fcn(inm,2,ilc);

    % ブレース省略
    if nmtype(inm) == PRM.BRACE
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
        % 組合せ応力度比 sqrt(σ^2+3τ^2)/ft（角形・円形鋼管等）
        %   σ = 軸+両曲げの縁応力度（端部ごとの絶対値和）
        %   τ = 端部せん断応力度（X方向=9列, Y方向=8列）
        %   断面算定表に表示する内訳値。検定比一覧には用いない。
        ftc = ftn(inm,ilc_);
        sgb = abs(st(inm,1,ilc)) + abs(st(inm,5,ilc)) + abs(st(inm,6,ilc));
        sgt = abs(st(inm,1,ilc)) + abs(st(inm,11,ilc)) ...
          + abs(st(inm,12,ilc));
        tcx = abs(st(inm,9,ilc));
        tcy = abs(st(inm,8,ilc));
        ration(inm,15,ilc) = sqrt(sgb^2 + 3*tcx^2) / ftc;
        ration(inm,16,ilc) = sqrt(sgb^2 + 3*tcy^2) / ftc;
        ration(inm,17,ilc) = sqrt(sgt^2 + 3*tcx^2) / ftc;
        ration(inm,18,ilc) = sqrt(sgt^2 + 3*tcy^2) / ftc;
      case PRM.GIRDER
        % 中央σb/fb — 引張時はfb=ft（引張正）
        if Ncn(inm,ilc) > 0
          fbn(inm,3,ilc) = ftn(inm,ilc_);
        end
        ration(inm,13,ilc) = stc(inm,ilc) / fbn(inm,3,ilc);
        % 中央N/fc（引張正）
        stcn_N = Ncn(inm,ilc) / A(inm);
        if stcn_N > 0
          fcn(inm,3,ilc) = ftn(inm,ilc_);
          ration(inm,14,ilc) = stcn_N / ftn(inm,ilc_);
        else
          ration(inm,14,ilc) = stcn_N / fcn(inm,3,ilc);
        end
    end
  end
end

return
end
