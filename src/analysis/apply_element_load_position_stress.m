function [dfn0, nominal] = apply_element_load_position_stress( ...
  dfn0, element, nominal_girder, idmg2m, lm, lf)
%apply_element_load_position_stress - 梁の断面算定位置へ直接値を反映する
%
%   [dfn0, nominal] = apply_element_load_position_stress(dfn0,
%   element, nominal_girder, idmg2m, lm, lf) は、名目梁
%   端部の現在フェイス位置を二次曲線で評価し、1/4位置せん断力との
%   危険側を設計応力へ反映する。
%
%   入力引数:
%     dfn0            - ケース別名目部材設計応力
%     element         - 要素別1/4位置応力
%     nominal_girder  - 名目梁情報
%     idmg2m          - 梁番号から部材番号への対応
%     lm              - 要素長
%     lf              - フェイス長構造体
%
%   出力引数:
%     dfn0    - 直接入力値を反映した設計応力
%     nominal - 名目梁端側1/4位置の曲げモーメント

nnm = size(dfn0, 1);
nlc = size(dfn0, 3);
nominal.M = nan(nnm, 2, nlc);
% 直接入力が1件も無いモデルでは名目梁の走査を行わない
if ~any(~isnan(element.M(:, [2, 4], :)), 'all') ...
    && ~any(~isnan(element.Q), 'all')
  return
end
for ing = 1:size(nominal_girder.idmeg, 1)
  igs = nominal_girder.idmeg(ing, :);
  igs(igs == 0) = [];
  if isempty(igs)
    continue
  end
  inm = nominal_girder.idnominal(ing);
  end_girder = [igs(1), igs(end)];
  end_member = idmg2m(end_girder);
  face = [lf.girder(end_girder(1), 1), lf.girder(end_girder(2), 2)];
  for ilc = 1:nlc
    for iside = 1:2
      im = end_member(iside);
      sample_index = 2 * iside;
      if ~isnan(element.M(im, sample_index, ilc))
        nominal.M(inm, iside, ilc) = element.M(im, sample_index, ilc);
        position = face(iside) / lm(im);
        samples = reshape(element.M(im, :, ilc), 1, 5);
        moment = evaluate_face_moment(samples, position, iside);
        force_column = 5 + 6 * (iside - 1);
        dfn0(inm, force_column, ilc) = (-1) ^ iside * moment;
      end
      if ~isnan(element.Q(im, iside, ilc))
        quarter_q = element.Q(im, iside, ilc);
        force_column = 3 + 6 * (iside - 1);
        if face(iside) <= lm(im) / 4
          end_q = dfn0(inm, force_column, ilc);
          dfn0(inm, force_column, ilc) = absmax(end_q, quarter_q);
        else
          dfn0(inm, force_column, ilc) = quarter_q;
        end
      end
    end
  end
end

return
end

function moment = evaluate_face_moment(samples, position, iside)
%evaluate_face_moment - 端部・1/4・中央の3点を通る二次曲線を評価する
%
%   moment = evaluate_face_moment(samples, position, iside) は、対象端側の
%   3標本を通る二次曲線を作り、指定したフェイス位置の値を求める。
%
%   入力引数:
%     samples  - i端からj端までの5位置の曲げモーメント [1×5]
%     position - 対象端からフェイスまでの部材長比
%     iside    - 対象端（1:i端、2:j端）
%
%   出力引数:
%     moment - フェイス位置の曲げモーメント
if iside == 1
  x = [0, 0.25, 0.5];
  y = samples(1:3);
else
  position = 1 - position;
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
