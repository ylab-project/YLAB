function [ration, fcn, fbn] = calc_nominal_allowable_stress_ratio(...
  st, ftn, fcn, fbn, fsn, nmtype, Ncn, An, girder_axial_mask, ...
  axial_tension)
%calc_nominal_allowable_stress_ratio - 公称許容応力度比の算定
%
%   [ration, fcn, fbn] = calc_nominal_allowable_stress_ratio(...) は、
%   端部軸力が引張となる位置でfcn・fbnをftnへ置換し、位置・成分別の
%   許容応力度比を算定する。
%
%   入力引数:
%     st                - 名目部材の応力度 [nnm×ncomp×nlc]
%     ftn               - 許容引張応力度 [nnm×2]
%     fcn               - 許容圧縮応力度（引張置換前）[nnm×3×nlc]
%     fbn               - 許容曲げ応力度（引張置換前）[nnm×3×nlc]
%     fsn               - 許容せん断応力度 [nnm×2]
%     nmtype            - 名目部材の種別 [nnm×1]
%     Ncn               - 名目梁中央の軸力 [nng×nlc]
%     An                - 名目部材の断面積 [nnm×1]
%     girder_axial_mask - S梁の軸力考慮マスク (struct)
%     axial_tension     - 端部軸力の引張判定 [nnm×2×nlc]
%
%   出力引数:
%     ration - 位置・成分別の応力度比 [nnm×16×nlc]
%     fcn    - 引張置換後の許容圧縮応力度 [nnm×3×nlc]
%     fbn    - 引張置換後の許容曲げ応力度 [nnm×3×nlc]

% 定数
[nnm, ~, nlc] = size(st);

% 初期化（15,16列はS柱組合せ応力度比 柱脚・柱頭）
ration = zeros(nnm,16,nlc);

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

    is_girder = nmtype(inm) == PRM.GIRDER;
    use_axial_i = ~is_girder || girder_axial_mask.i(inm, ilc);
    use_axial_c = ~is_girder || girder_axial_mask.c(inm, ilc);
    use_axial_j = ~is_girder || girder_axial_mask.j(inm, ilc);
    is_tension_i = axial_tension(inm, 1, ilc);
    is_tension_j = axial_tension(inm, 2, ilc);

    % Ni：引張時は fc,fb ともに ft に置換（引張正）
    if use_axial_i && is_tension_i
      fcn(inm,1,ilc) = ftn(inm,ilc_);
      fbn(inm,1,ilc) = ftn(inm,ilc_);
    end

    % Nj：引張時は fc,fb ともに ft に置換（引張正）
    if use_axial_j && is_tension_j
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
        %   τ = 同端部のX/Yせん断応力度の大きい方
        %   断面算定表に表示する内訳値。検定比一覧には用いない。
        ftc = ftn(inm,ilc_);
        sgb = abs(st(inm,1,ilc)) + abs(st(inm,5,ilc)) + abs(st(inm,6,ilc));
        sgt = abs(st(inm,1,ilc)) + abs(st(inm,11,ilc)) ...
          + abs(st(inm,12,ilc));
        tc = max(abs(st(inm,9,ilc)), abs(st(inm,8,ilc)));
        ration(inm,15,ilc) = sqrt(sgb^2 + 3*tc^2) / ftc;
        ration(inm,16,ilc) = sqrt(sgt^2 + 3*tc^2) / ftc;
      case PRM.GIRDER
        % 梁中央は中央2区間選定後の確定値を呼び出し側で設定する。
        % 中央N/fc（引張正）
        stcn_N = Ncn(inm,ilc) / An(inm);
        if use_axial_c && Ncn(inm, ilc) >= PRM.TOL_FORCE_N
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
