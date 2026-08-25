function [dfn0, nominal] = apply_element_load_position_stress( ...
  dfn0, element, df0, nominal_girder, idmg2m, lm, lf, lcdir, ...
  is_rc_girder)
%apply_element_load_position_stress - 梁の断面算定位置へ直接値を反映する
%
%   [dfn0, nominal] = apply_element_load_position_stress(dfn0,
%   element, df0, nominal_girder, idmg2m, lm, lf, lcdir,
%   is_rc_girder) は、芯間位置の
%   直接入力値を名目梁へ対応付ける。曲げモーメントは内法1/4・3/4
%   位置で評価し、長期端部は節点位置の値を維持する。せん断力は
%   RC梁では内法1/4・3/4位置を含む要素、その他の梁では端部要素の
%   値を組合せ前のまま保持する。位置入力のない解析ケースでは
%   同要素の補正後Qを用いる。
%
%   入力引数:
%     dfn0            - ケース別名目部材設計応力
%     element         - 要素別1/4・3/4位置応力
%     df0             - ケース別要素設計応力
%     nominal_girder  - 名目梁情報
%     idmg2m          - 梁番号から部材番号への対応
%     lm              - 要素長
%     lf              - フェイス長構造体
%     lcdir           - 荷重ケース方向
%     is_rc_girder    - 名目部材別のRC梁判定
%
%   出力引数:
%     dfn0    - 直接入力値を反映した設計応力
%     nominal - 名目梁の1/4・3/4位置応力

nnm = size(dfn0, 1);
nlc = size(dfn0, 3);
nominal.M = nan(nnm, 2, nlc);
nominal.Q = nan(nnm, 2, nlc);
% 直接入力が1件も無いモデルでは名目梁の走査を行わない
if ~any(~isnan(element.M(:, [2, 4], :)), 'all') ...
    && ~any(~isnan(element.Q), 'all')
  return
end
[end_member, face] = get_nominal_girder_end_members( ...
  nominal_girder.idmeg, idmg2m, lf);
for ing = 1:size(nominal_girder.idmeg, 1)
  igs = nominal_girder.idmeg(ing, :);
  igs(igs == 0) = [];
  if isempty(igs)
    continue
  end
  inm = nominal_girder.idnominal(ing);
  im_igs = idmg2m(igs);
  sub_lm = lm(im_igs);
  sub_x0 = [0; cumsum(sub_lm(1:end-1))];
  lnom = sum(sub_lm);

  % 芯間座標の入力曲線を名目梁の内法1/4・3/4位置で評価する
  linner = lnom - sum(face(ing, :));
  xquarter = face(ing, 1) + [0.25, 0.75] * linner;
  quarter_member = zeros(1, 2);
  quarter_position = zeros(1, 2);
  for iside = 1:2
    ksub = find(sub_x0 <= xquarter(iside), 1, 'last');
    quarter_member(iside) = im_igs(ksub);
    quarter_position(iside) = ...
      (xquarter(iside) - sub_x0(ksub)) / sub_lm(ksub);
  end

  for iside = 1:2
    position = quarter_position(iside);
    if position <= 0.5
      sample_index = 2;
    else
      sample_index = 4;
    end
    for ilc = 1:nlc
      if ~isnan(element.M(quarter_member(iside), sample_index, ilc))
        samples = reshape(element.M(quarter_member(iside), :, ilc), 1, 5);
        nominal.M(inm, iside, ilc) = evaluate_position_moment( ...
          samples, position);
      end
    end
  end

  if any(~isnan(element.Q(im_igs, :, :)), 'all')
    for iside = 1:2
      if is_rc_girder(inm)
        im = quarter_member(iside);
      else
        im = end_member(ing, iside);
      end
      force_column = 3 + 6 * (iside - 1);
      for ilc = 1:nlc
        if ~isnan(element.Q(im, iside, ilc))
          nominal.Q(inm, iside, ilc) = element.Q(im, iside, ilc);
        else
          nominal.Q(inm, iside, ilc) = df0(im, force_column, ilc);
        end
      end
    end
  end

  for iside = 1:2
    sample_index = 2 * iside;
    force_column = 5 + 6 * (iside - 1);
    if iside == 1
      position = face(ing, iside) / lm(end_member(ing, iside));
    else
      position = 1 - face(ing, iside) / lm(end_member(ing, iside));
    end
    for ilc = 1:nlc
      % 長期端部Mは節点位置、地震時端部Mはフェイス位置を用いる
      if lcdir(ilc) == PRM.LT
        continue
      end
      if isnan(element.M(end_member(ing, iside), sample_index, ilc))
        continue
      end
      samples = reshape(element.M(end_member(ing, iside), :, ilc), 1, 5);
      moment = evaluate_position_moment(samples, position);
      dfn0(inm, force_column, ilc) = (-1) ^ iside * moment;
    end
  end
end

return
end

function moment = evaluate_position_moment(samples, position)
%evaluate_position_moment - 端部・1/4・中央の二次曲線を評価する
%
%   moment = evaluate_position_moment(samples, position) は、指定位置を
%   含む側の3標本を通る二次曲線から曲げモーメントを求める。
%
%   入力引数:
%     samples  - i端からj端までの5位置の曲げモーメント [1×5]
%     position - i端から評価位置までの部材長比
%
%   出力引数:
%     moment - 評価位置の曲げモーメント
if position <= 0.5
  x = [0, 0.25, 0.5];
  y = samples(1:3);
else
  x = [0.5, 0.75, 1];
  y = samples(3:5);
end
position = min(max(position, x(1)), x(3));
moment = 0;
for inode = 1:3
  others = setdiff(1:3, inode);
  basis = prod(position - x(others)) / prod(x(inode) - x(others));
  moment = moment + y(inode) * basis;
end

return
end
