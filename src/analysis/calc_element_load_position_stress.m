function stress = calc_element_load_position_stress(rs0, M0, lm, records)
%calc_element_load_position_stress - 要素別1/4位置応力を逆算する
%
%   stress = calc_element_load_position_stress(rs0, M0, lm, records) は、
%   解析端部結果へ行別の中間荷重成分を重ね、構造スパン1/4・3/4
%   位置の曲げモーメントとせん断力を求める。
%
%   入力引数:
%     rs0     - ケース別部材応力 [nme×12×nlc]
%     M0      - 中央位置の中間荷重曲げモーメント [nme×nlc]
%     lm      - 要素長 [nme×1]
%     records - 要素荷重の位置応力入力レコード
%
%   出力引数:
%     stress - 要素別標本値と直接入力有無を持つ構造体
%
%   備考:
%     - 未入力の行は現行放物線の1/4位置成分0.75*M0を用いる。
%     - 数値0は直接入力値として扱い、NaNだけを未入力とする。

[nme, ~, nlc] = size(rs0);
stress.M = nan(nme, 5, nlc);
stress.Q = nan(nme, 2, nlc);
stress.has_M = false(nme, 2, nlc);
stress.has_Q = false(nme, 2, nlc);
if isempty(records)
  return
end

% 入力レコードが存在する (部材, ケース) の組だけを処理する
rec_idme = [records.idme];
rec_ilc = [records.ilc];
pairs = unique([rec_idme(:), rec_ilc(:)], 'rows');
for ipair = 1:size(pairs, 1)
  im = pairs(ipair, 1);
  ilc = pairs(ipair, 2);
  selected = records(rec_idme == im & rec_ilc == ilc);
  quarter = vertcat(selected.quarter);
  m0_record = vertcat(selected.M0);
  Mi = -rs0(im, 5, ilc);
  Mj = rs0(im, 11, ilc);
  M0_total = M0(im, ilc);
  Mc = 0.5 * Mi + 0.5 * Mj + M0_total;
  stress.M(im, [1, 3, 5], ilc) = [Mi, Mc, Mj];
  for iside = 1:2
    mcolumn = 2 * iside - 1;
    qcolumn = 2 * iside;
    direct_m = ~isnan(quarter(:, mcolumn));
    if any(direct_m)
      middle = 0.75 * M0_total + sum(quarter(direct_m, mcolumn) ...
        - 0.75 * m0_record(direct_m));
      if iside == 1
        stress.M(im, 2, ilc) = 0.75 * Mi + 0.25 * Mj + middle;
      else
        stress.M(im, 4, ilc) = 0.25 * Mi + 0.75 * Mj + middle;
      end
      stress.has_M(im, iside, ilc) = true;
    end

    direct_q = ~isnan(quarter(:, qcolumn));
    if any(direct_q)
      q0 = sum(quarter(direct_q, qcolumn));
      moment_component = (Mi + Mj) / lm(im);
      if iside == 1
        stress.Q(im, 1, ilc) = q0 + moment_component;
      else
        stress.Q(im, 2, ilc) = q0 - moment_component;
      end
      stress.has_Q(im, iside, ilc) = true;
    end
  end
end

return
end
