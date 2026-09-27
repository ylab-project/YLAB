function [ration, fcn, fbny, fbnz] = ...
  calc_nominal_allowable_stress_ratio(st, ftn, fcn, fbny, fbnz, fsn, ...
  nmtype, Ncn, An, girder_axial_mask, axial_tension)
%calc_nominal_allowable_stress_ratio - 公称許容応力度比の算定
%
%   [ration, fcn, fbny, fbnz] = calc_nominal_allowable_stress_ratio(...)
%   は、端部軸力が引張となる位置でfcn・fbny・fbnzをftnへ置換し、
%   位置・成分別の許容応力度比を算定する。
%
%   入力引数:
%     st                - 名目部材の応力度 [nnm×ncomp×nlc]
%     ftn               - 許容引張応力度 [nnm×2]
%     fcn               - 許容圧縮応力度（引張置換前）[nnm×3×nlc]
%     fbny              - 局所y軸まわりの許容曲げ応力度（引張置換前）
%                         [nnm×3×nlc]
%     fbnz              - 局所z軸まわりの許容曲げ応力度（引張置換前）
%                         [nnm×3×nlc]
%     fsn               - 許容せん断応力度 [nnm×2]
%     nmtype            - 名目部材の種別 [nnm×1]
%     Ncn               - 名目梁中央の軸力 [nng×nlc]
%     An                - 名目部材の断面積 [nnm×1]
%     girder_axial_mask - S梁の軸力考慮マスク (struct)
%     axial_tension     - 端部軸力の引張判定 [nnm×2×nlc]
%
%   出力引数:
%     ration - 位置・成分別の応力度比 [nnm×PRM.RATION_NCOL×nlc]
%     fcn    - 引張置換後の許容圧縮応力度 [nnm×3×nlc]
%     fbny   - 引張置換後の局所y軸まわりの許容曲げ応力度 [nnm×3×nlc]
%     fbnz   - 引張置換後の局所z軸まわりの許容曲げ応力度 [nnm×3×nlc]

% 定数
[nnm, ~, nlc] = size(st);

% 初期化（13,14列は梁中央の曲げ・軸力比、15,16列はS柱の組合せ応力度比
% 柱脚・柱頭で、いずれも呼び出し側が設定する。組合せ応力度比は制約には
% 用いず帳票表示だけに使い、最終解析時だけ算定して算定しない柱は NaN
% とする。17,18列は梁の鉛直方向せん断検定比 i端・j端）
ration = zeros(nnm,PRM.RATION_NCOL,nlc);

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
      fbny(inm,1,ilc) = ftn(inm,ilc_);
      fbnz(inm,1,ilc) = ftn(inm,ilc_);
    end

    % Nj：引張時は fc,fb ともに ft に置換（引張正）
    if use_axial_j && is_tension_j
      fcn(inm,2,ilc) = ftn(inm,ilc_);
      fbny(inm,2,ilc) = ftn(inm,ilc_);
      fbnz(inm,2,ilc) = ftn(inm,ilc_);
    end

    % 軸力度
    ration(inm,1,ilc) = st(inm,1,ilc)/fcn(inm,1,ilc);
    ration(inm,7,ilc) = st(inm,7,ilc)/fcn(inm,2,ilc);

    % ブレース省略
    if nmtype(inm) == PRM.BRACE
      continue
    end

    % せん断応力度（局所軸成分。柱の検定に用いる。梁のせん断
    % 検定は鉛直方向の射影値による。下の梁の処理を参照）
    ration(inm,2,ilc) = st(inm,2,ilc)/fsn(inm,ilc_);
    ration(inm,3,ilc) = st(inm,3,ilc)/fsn(inm,ilc_);
    ration(inm,8,ilc) = st(inm,8,ilc)/fsn(inm,ilc_);
    ration(inm,9,ilc) = st(inm,9,ilc)/fsn(inm,ilc_);

    % 曲げ応力度（局所y軸まわり。梁とX方向強軸の柱の強軸）
    ration(inm,5,ilc) = st(inm,5,ilc)/fbny(inm,1,ilc);
    ration(inm,11,ilc) = st(inm,11,ilc)/fbny(inm,2,ilc);

    % 曲げ応力度（局所z軸まわり。Y方向強軸の柱の強軸、その他は弱軸）
    ration(inm,6,ilc) = st(inm,6,ilc)/fbnz(inm,1,ilc);
    ration(inm,12,ilc) = st(inm,12,ilc)/fbnz(inm,2,ilc);

    if is_girder
      % 鉛直方向せん断の検定比（梁のせん断検定はこの値を使う）
      fs_ = fsn(inm,ilc_);
      ration(inm,PRM.RATION_TAUV_I,ilc) = st(inm,PRM.STN_TAUV_I,ilc)/fs_;
      ration(inm,PRM.RATION_TAUV_J,ilc) = st(inm,PRM.STN_TAUV_J,ilc)/fs_;

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
