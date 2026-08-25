function dfn = apply_element_load_position_shear(dfn, position_q, ...
  nominal_girder, idmg2m, lm, lf)
%apply_element_load_position_shear - 断面算定位置のせん断力を採用する
%
%   dfn = apply_element_load_position_shear(dfn, position_q,
%   nominal_girder, idmg2m, lm, lf) は、設計ケースへ重ね合わせた
%   端部Qと1/4・3/4位置Qから、SS7マニュアル計算編6.3.8に従って断面算定
%   位置のせん断力を採用する。
%
%   入力引数:
%     dfn             - 重ね合わせ後の名目部材設計応力
%     position_q      - 重ね合わせ後の名目梁1/4・3/4位置Q
%     nominal_girder  - 名目梁情報
%     idmg2m          - 梁番号から部材番号への対応
%     lm              - 要素長
%     lf              - フェイス長構造体
%
%   出力引数:
%     dfn - 位置Qを反映した名目部材設計応力
if ~any(~isnan(position_q), 'all')
  return
end

[end_member, face] = get_nominal_girder_end_members( ...
  nominal_girder.idmeg, idmg2m, lf);
for ing = 1:size(nominal_girder.idmeg, 1)
  inm = nominal_girder.idnominal(ing);
  if all(isnan(position_q(inm, :, :)), 'all')
    continue
  end
  if all(end_member(ing, :) == 0)
    continue
  end

  for iside = 1:2
    im = end_member(ing, iside);
    force_column = 3 + 6 * (iside - 1);
    if face(ing, iside) <= lm(im) / 4
      for ilc = 1:size(dfn, 3)
        quarter_q = position_q(inm, iside, ilc);
        if isnan(quarter_q)
          continue
        end
        end_q = dfn(inm, force_column, ilc);
        dfn(inm, force_column, ilc) = absmax(end_q, quarter_q);
      end
    else
      for ilc = 1:size(dfn, 3)
        quarter_q = position_q(inm, iside, ilc);
        if isnan(quarter_q)
          continue
        end
        dfn(inm, force_column, ilc) = quarter_q;
      end
    end
  end
end

return
end
