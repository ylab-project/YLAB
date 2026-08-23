function stress = calc_element_load_position_stress( ...
  rs0, M0, lm, element_force)
%calc_element_load_position_stress - 要素別1/4位置応力を逆算する
%
%   stress = calc_element_load_position_stress(rs0, M0, lm, ...
%   element_force) は、
%   解析端部結果へ行別の中間荷重成分を重ね、構造スパン1/4・3/4
%   位置の曲げモーメントとせん断力を求める。
%
%   入力引数:
%     rs0     - ケース別部材応力 [nme×12×nlc]
%     M0      - 中央位置の中間荷重曲げモーメント [nme×nlc]
%     lm      - 要素長 [nme×1]
%     element_force - 共通内部データの線材荷重テーブル
%
%   出力引数:
%     stress - 要素別の1/4位置応力
%
%   備考:
%     - 合計M0を基準に、直接入力行の既存成分だけを置き換える。
%     - 数値0は直接入力値として扱い、NaNだけを未入力とする。
%     - 式はSS7計算編6.3.7〜6.3.9の元PDFと照合済みである。

[nme, ~, nlc] = size(rs0);
stress.M = nan(nme, 5, nlc);
stress.Q = nan(nme, 2, nlc);
if isempty(element_force)
  return
end

% 行ごとの参照は列配列へ取り出してから索引する
row_idme = element_force.idme;
row_ilc = element_force.ilc;
row_quarter = element_force.quarter;
row_M0 = element_force.M0;

% 解析対象の入力レコードが存在する組だけを処理する
pairs = unique([row_idme, row_ilc], 'rows');
pairs(pairs(:, 2) == 0, :) = [];
for ipair = 1:size(pairs, 1)
  im = pairs(ipair, 1);
  ilc = pairs(ipair, 2);
  selected = row_idme == im & row_ilc == ilc;
  quarter = row_quarter(selected, :);
  m0_values = row_M0(selected);
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
        - 0.75 * m0_values(direct_m));
      if iside == 1
        stress.M(im, 2, ilc) = 0.75 * Mi + 0.25 * Mj + middle;
      else
        stress.M(im, 4, ilc) = 0.25 * Mi + 0.75 * Mj + middle;
      end
    end

    direct_q = ~isnan(quarter(:, qcolumn));
    if any(direct_q)
      moment_component = (Mi + Mj) / lm(im);
      m0_component = 2 * M0_total / lm(im);
      row_component = 2 * m0_values(direct_q) / lm(im);
      if iside == 1
        correction = sum(quarter(direct_q, qcolumn) - row_component);
        stress.Q(im, 1, ilc) = moment_component + m0_component ...
          + correction;
      else
        correction = sum(quarter(direct_q, qcolumn) + row_component);
        stress.Q(im, 2, ilc) = -moment_component - m0_component ...
          + correction;
      end
    end
  end
end

return
end