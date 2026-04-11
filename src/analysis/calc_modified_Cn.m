function Cn = calc_modified_Cn(rs, M0, lm, nomgc, idg2m, ...
  is_through_girder, idmeg)
%calc_modified_Cn - 名目梁4検定位置の修正係数Cnを算定
%
%   Cn = calc_modified_Cn(rs, M0, lm, nomgc, idg2m,
%   is_through_girder, idmeg) は、名目梁の4検定位置（左端、右端、
%   中央L、中央R）ごとに、その位置が属する座屈区間のC値を算定
%   する。通し梁区間は C=1 のまま据え置く。
%
%   入力引数:
%     rs                - 部材応力 [nme×12×nlc]
%     M0                - 付加曲げモーメント [nme×1]
%     lm                - 部材長 [nme×1]
%     nomgc             - 4検定位置情報構造体
%                         .lb [nng×4] 横補剛間隔
%                         .xc [nng×3] 中央座屈区間の絶対座標
%     idg2m             - 梁→部材インデックス [nmeg×1]
%     is_through_girder - 通し梁フラグ [nmeg×2]
%     idmeg             - 名目梁→sub梁 [nng×nsub]
%
%   出力引数:
%     Cn - 名目梁4位置のC [nng×4×nlc]

% 計算の準備
nlc = size(rs, 3);
nng = size(idmeg, 1);
lb = nomgc.lb;
lxc = nomgc.xc;
Cn = ones(nng, 4, nlc);

for ilc = 1:nlc
  for ing = 1:nng
    % この名目梁の分割部材を取得
    igs = idmeg(ing,:);
    igs(igs==0) = [];
    nsub = length(igs);
    ig0 = igs(1);

    % 各分割部材のM分布データ収集
    sub_Ml = zeros(nsub, 1);
    sub_Mr = zeros(nsub, 1);
    sub_M0 = zeros(nsub, 1);
    sub_lm = zeros(nsub, 1);
    for k = 1:nsub
      im = idg2m(igs(k));
      sub_Ml(k) = -rs(im, 5, ilc);
      sub_Mr(k) = rs(im, 11, ilc);
      sub_M0(k) = M0(im, 1);
      sub_lm(k) = lm(im);
    end
    sub_x0 = [0; cumsum(sub_lm(1:end-1))];
    l = sum(sub_lm);

    % 各分割部材の極値からMmax/lmaxを算定
    Mmax = 0;
    lmax = 0;
    for k = 1:nsub
      M0k = sub_M0(k);
      lk = sub_lm(k);
      if abs(M0k) < 1e-10
        continue
      end
      Mlk = sub_Ml(k);
      Mrk = sub_Mr(k);
      t = lk*(4*M0k+Mlk-Mrk)/(8*M0k);
      if t <= 0 || t >= lk
        continue
      end
      Mext = abs(4*M0k*t^2/lk^2 + (Mrk-Mlk-4*M0k)*t/lk + Mlk);
      if Mext > Mmax
        Mmax = Mext;
        lmax = sub_x0(k) + t;
      end
    end

    % 名目部材端部モーメント
    Ml_nom = sub_Ml(1);
    Mr_nom = sub_Mr(end);

    % 名目梁レベルの通し梁判定
    is_thr_l = is_through_girder(ig0, 1);
    is_thr_r = is_through_girder(igs(end), 2);

    % 4位置のC値算定
    for jcol = 1:4
      % 通し梁チェック（col1:左端, col2:右端,
      %   col3/4:中央）
      if jcol == 1
        if is_thr_l, continue; end
      elseif jcol == 2
        if is_thr_r, continue; end
      else
        if is_thr_l || is_thr_r
          continue
        end
      end

      % 座屈区間の端点座標（名目梁基準）
      if jcol == 1
        xa = 0;
        xb = min(lb(ing, 1), l);
      elseif jcol == 2
        xa = l - min(lb(ing, 2), l);
        xb = l;
      elseif jcol == 3
        % 中央L: xc絶対座標から取得
        xa = lxc(ing, 1);
        xb = lxc(ing, 2);
      else
        % 中央R: isnan(xc(3))で判定
        if isnan(lxc(ing, 3))
          xa = lxc(ing, 1);
          xb = lxc(ing, 2);
        else
          xa = lxc(ing, 2);
          xb = lxc(ing, 3);
        end
      end

      % M値の取得（区分的放物線で直接評価）
      if abs(xa) < 1e-10
        Ma = Ml_nom;
      else
        ksub_ = find(sub_x0 <= xa, 1, 'last');
        t_ = xa - sub_x0(ksub_);
        lk_ = sub_lm(ksub_);
        Ma = 4*sub_M0(ksub_)*t_^2/lk_^2 ...
          + (sub_Mr(ksub_) - sub_Ml(ksub_) - 4*sub_M0(ksub_)) ...
          *t_/lk_ + sub_Ml(ksub_);
      end
      if abs(xb - l) < 1e-10
        Mb = Mr_nom;
      else
        ksub_ = find(sub_x0 <= xb, 1, 'last');
        t_ = xb - sub_x0(ksub_);
        lk_ = sub_lm(ksub_);
        Mb = 4*sub_M0(ksub_)*t_^2/lk_^2 ...
          + (sub_Mr(ksub_) - sub_Ml(ksub_) - 4*sub_M0(ksub_)) ...
          *t_/lk_ + sub_Ml(ksub_);
      end

      % 対称変形モード
      if xa < lmax && lmax < xb && max(abs([Ma Mb])) < Mmax
        continue
      end

      % 逆称変形モード
      if abs(Ma) >= abs(Mb)
        M1 = Ma; M2 = Mb;
      else
        M1 = Mb; M2 = Ma;
      end
      Cval = 1.75 - 1.05*(M2/M1) + 0.3*(M2/M1)^2;
      Cn(ing, jcol, ilc) = Cval;
    end
  end
end

% 上限値
Cn(Cn >= 2.3) = 2.3;

return
end
