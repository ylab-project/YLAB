function nomgc = calc_nominal_girder_check_interval(lbng, lmg, lfg, idmeg)
%calc_nominal_girder_check_interval - 名目梁4検定位置の情報を算定
%
%   nomgc = calc_nominal_girder_check_interval(lbng, lmg, lfg, idmeg) は、
%   名目梁の4検定位置（左端、右端、中央L、中央R）に対応するlb、
%   subインデックス、中央座屈区間xcを算定する。中央位置は内法
%   スパン中央（柱面間距離の中央）で算出する。
%
%   入力引数:
%     lbng  [nng×2]    - 横補剛間隔（名目梁単位）[左, 右]
%     lmg   [nmg×1]    - 梁部材長（sub部材単位）
%     lfg   [nmg×2]    - 梁フェイス長 [左, 右]
%     idmeg [nng×nsub] - 名目梁→sub梁インデックス
%
%   出力引数:
%     nomgc - 名目梁検定位置情報の構造体
%       .lb        [nng×4] - 各検定位置のlb
%       .xc        [nng×3] - 中央座屈区間の絶対座標
%       .xc_design [nng×1] - 断面算定の中央位置（内法スパン中央）
%       .idsub     [nng×4] - 属するsub番号(名目梁内)

nng = size(idmeg, 1);
nomgc.lb = zeros(nng, 4);
nomgc.xc = nan(nng, 3);
nomgc.xc_design = zeros(nng, 1);
nomgc.idsub = zeros(nng, 4);

for ing = 1:nng
  igs = idmeg(ing,:);
  igs(igs==0) = [];
  nsub = length(igs);

  % lb: 左右端は入力値、中央はxcから算定
  lb1 = lbng(ing, 1);
  lb2 = lbng(ing, 2);

  % 名目梁長と内法スパン中央
  sub_lm = lmg(igs);
  lnom = sum(sub_lm);
  lf_l = lfg(igs(1), 1);
  lf_r = lfg(igs(end), 2);
  xc_center = lf_l + (lnom - lf_l - lf_r) / 2;
  nomgc.xc_design(ing, 1) = xc_center;

  % xc（中央座屈区間）の算定
  xc_row = calc_xc_row(lnom, lb1, lb2, xc_center);
  nomgc.xc(ing, :) = xc_row;

  % lb col3/col4: 中央L/Rのlb
  if isnan(xc_row(3))
    % 分割一致なし: 1区間
    nomgc.lb(ing,:) = [lb1 lb2 xc_row(2)-xc_row(1) xc_row(2)-xc_row(1)];
  else
    % 分割一致あり: 2区間
    nomgc.lb(ing,:) = [lb1 lb2 xc_row(2)-xc_row(1) xc_row(3)-xc_row(2)];
  end

  % idsub: 各検定位置が属するsub番号
  % col1: 左端 → sub1
  nomgc.idsub(ing,1) = 1;
  % col2: 右端 → 最後のsub
  nomgc.idsub(ing,2) = nsub;

  % col3/col4: 中央
  if nsub == 1
    nomgc.idsub(ing,3:4) = 1;
  else
    % 分割梁: 中央位置の判定
    sub_x0 = [0; cumsum(sub_lm(1:end-1))];

    % 中央がsub境界と一致するか判定
    is_at_split = false;
    for k = 2:nsub
      if abs(xc_center - sub_x0(k)) < 1e-6
        is_at_split = true;
        nomgc.idsub(ing,3) = k-1;
        nomgc.idsub(ing,4) = k;
        break
      end
    end

    if ~is_at_split
      % 中央がsub内部に位置
      ksub = find(sub_x0 <= xc_center, 1, 'last');
      nomgc.idsub(ing,3:4) = ksub;
    end
  end
end

return
end
