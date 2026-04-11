function [C, Mc_nom] = calc_modified_C(rs, M0, lm, lb, lxc, idg2m, ...
  is_through_girder, idmeg, Mc)
%calc_modified_C - 修正係数Cと名目梁中央Mcの算定
%
%   [C, Mc_nom] = calc_modified_C(rs, M0, lm, lb, lxc, idg2m,
%   is_through_girder, idmeg, Mc) は、名目梁単位で横補剛区間3区画
%   （左端・右端・中央）の修正係数Cを算定するとともに、名目梁
%   中央位置の曲げモーメントMc_nomを区分的放物線評価で算定する。
%   通し梁区間は計算対象外とし、C=1のまま据え置く。
%
%   入力引数:
%     rs                - 部材端応力 [nme×12×nlc]
%     M0                - 付加曲げモーメント [nme×1]
%     lm                - 部材長 [nme×1]
%     lb                - 横補剛間隔 [nng×2]
%     lxc               - 中央座屈区間端点座標 [nng×2]
%     idg2m             - 梁→部材インデックス [nmeg×1]
%     is_through_girder - 通し梁フラグ [nmeg×2]
%     idmeg             - 名目梁→sub梁 [nng×nsub]
%     Mc                - 名目梁中央Mc初期値 [nmeg×nlc]
%
%   出力引数:
%     C      - 修正係数C [nmeg×3×nlc]
%     Mc_nom - 名目梁中央M [nmeg×nlc]

% 計算の準備
nlc = size(rs, 3);
nmeg = size(is_through_girder, 1);
C = ones(nlc*3, nmeg);
nng = size(idmeg, 1);
Mc_nom = Mc;

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

    % 名目梁中央Mc（区分的放物線評価）
    if nsub > 1
      x_ = l/2;
      ksub_ = find(sub_x0 <= x_, 1, 'last');
      t_ = x_ - sub_x0(ksub_);
      lk_ = sub_lm(ksub_);
      Mc_nom(ig0, ilc) = 4*sub_M0(ksub_)*t_^2/lk_^2 ...
        + (sub_Mr(ksub_) - sub_Ml(ksub_) ...
        - 4*sub_M0(ksub_))*t_/lk_ + sub_Ml(ksub_);
    end

    % 横補剛区間（名目部材単位）
    lb1 = min(lb(ing, 1), l);
    lb2 = min(lb(ing, 2), l);
    lxc12 = [lxc(ing, 1) lxc(ing, 2)];

    % 各分割部材の極値からMmax/lmaxを算定
    Mmax = 0;
    lmax = 0;
    for k = 1:nsub
      M0k = sub_M0(k);
      lk = sub_lm(k);
      if abs(M0k) < 1e-10, continue; end
      Mlk = sub_Ml(k);
      Mrk = sub_Mr(k);
      t = lk*(4*M0k + Mlk - Mrk)/(8*M0k);
      if t <= 0 || t >= lk, continue; end
      Mext = abs(4*M0k*t^2/lk^2 + (Mrk - Mlk - 4*M0k)*t/lk + Mlk);
      if Mext > Mmax
        Mmax = Mext;
        lmax = sub_x0(k) + t;
      end
    end

    % 名目部材端部モーメント
    Ml_nom = sub_Ml(1);
    Mr_nom = sub_Mr(end);

    % 名目梁レベルの通し梁判定
    is_thr = [is_through_girder(ig0, 1) is_through_girder(igs(end), 2)];
    is_thr(3) = is_thr(1) || is_thr(2);

    % 3区間（左端、右端、中央）のC値算定
    for j = 1:3
      if is_thr(j), continue; end
      switch j
        case 1
          % M(lb1)を区分的放物線で直接評価
          x_ = lb1;
          ksub_ = find(sub_x0 <= x_, 1, 'last');
          t_ = x_ - sub_x0(ksub_);
          lk_ = sub_lm(ksub_);
          Mx_ = 4*sub_M0(ksub_)*t_^2/lk_^2 ...
            + (sub_Mr(ksub_) - sub_Ml(ksub_) - 4*sub_M0(ksub_)) ...
            *t_/lk_ + sub_Ml(ksub_);
          M12 = [Ml_nom Mx_];
          x12 = [0 lb1];
        case 2
          % M(l-lb2)を区分的放物線で直接評価
          x_ = l - lb2;
          ksub_ = find(sub_x0 <= x_, 1, 'last');
          t_ = x_ - sub_x0(ksub_);
          lk_ = sub_lm(ksub_);
          Mx_ = 4*sub_M0(ksub_)*t_^2/lk_^2 ...
            + (sub_Mr(ksub_) - sub_Ml(ksub_) - 4*sub_M0(ksub_)) ...
            *t_/lk_ + sub_Ml(ksub_);
          M12 = [Mx_ Mr_nom];
          x12 = [l - lb2 l];
        case 3
          % M(lxc12)を区分的放物線で直接評価（2要素）
          M12 = zeros(1, 2);
          for ix_ = 1:2
            x_ = lxc12(ix_);
            ksub_ = find(sub_x0 <= x_, 1, 'last');
            t_ = x_ - sub_x0(ksub_);
            lk_ = sub_lm(ksub_);
            M12(ix_) = 4*sub_M0(ksub_)*t_^2/lk_^2 ...
              + (sub_Mr(ksub_) - sub_Ml(ksub_) - 4*sub_M0(ksub_)) ...
              *t_/lk_ + sub_Ml(ksub_);
          end
          x12 = lxc12;
      end

      % 対称変形モード
      if x12(1) < lmax && lmax < x12(2) && max(abs(M12)) < Mmax
        continue
      end

      % 逆称変形モード
      if abs(M12(1)) >= abs(M12(2))
        M1 = M12(1); M2 = M12(2);
      else
        M1 = M12(2); M2 = M12(1);
      end
      Cval = 1.75 - 1.05*(M2/M1) + 0.3*(M2/M1)^2;

      % 全分割部材に同じC値を設定
      for k = 1:nsub
        C(3*(ilc-1)+j, igs(k)) = Cval;
      end
    end
  end
end

% TODO: とりあえず
C(C >= 2.3) = 2.3;

% 並べ替え（(左端,右端,中央)×nlc → nmeg×3×nlc）
C_ = C;
C = zeros(nmeg, 3, nlc);
for ilc = 1:nlc
  for ig = 1:nmeg
    id = (ilc-1)*3;
    C(ig, 1, ilc) = C_(id+1, ig);
    C(ig, 2, ilc) = C_(id+2, ig);
    C(ig, 3, ilc) = C_(id+3, ig);
  end
end

return
end
