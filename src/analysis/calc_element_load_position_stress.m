function stress = calc_element_load_position_stress( ...
  rs0, M0, lm, element_force)
%calc_element_load_position_stress - 要素別1/4・3/4位置応力を算出する
%
%   stress = calc_element_load_position_stress(rs0, M0, lm, ...
%   element_force) は、
%   解析端部結果へ行別の中間荷重成分を重ね、構造スパン1/4・3/4
%   位置の曲げモーメントとせん断力を求める。曲げは直接入力位置の
%   ある要素について全解析ケースで算出し、せん断力は位置入力の
%   ある解析ケースについて算出する。
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
%     - 式はSS7マニュアル計算編6.3.7〜6.3.9の元PDFと照合済みである。

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

% 解析対象行のある要素は全解析ケースを走査する
for im = reshape(unique(row_idme(row_ilc > 0)), 1, [])
  selected = row_idme == im & row_ilc > 0;
  row_ilc_ = row_ilc(selected);
  row_quarter_ = row_quarter(selected, :);
  row_M0_ = row_M0(selected);
  Mi = reshape(-rs0(im, 5, :), 1, nlc);
  Mj = reshape(rs0(im, 11, :), 1, nlc);
  M0_total = M0(im, :);
  Mc = 0.5 * Mi + 0.5 * Mj + M0_total;
  stress.M(im, [1, 3, 5], :) = reshape([Mi; Mc; Mj], 1, 3, nlc);

  for iside = 1:2
    mcolumn = 2 * iside - 1;
    if ~any(~isnan(row_quarter_(:, mcolumn)))
      continue
    end
    for ilc = 1:nlc
      selected = row_ilc_ == ilc;
      quarter = row_quarter_(selected, mcolumn);
      m0_values = row_M0_(selected);
      selected = ~isnan(quarter);
      middle = 0.75 * M0_total(ilc) + sum(quarter(selected) ...
        - 0.75 * m0_values(selected));
      if iside == 1
        stress.M(im, 2, ilc) = 0.75 * Mi(ilc) + 0.25 * Mj(ilc) + middle;
      else
        stress.M(im, 4, ilc) = 0.25 * Mi(ilc) + 0.75 * Mj(ilc) + middle;
      end
    end
  end

  for ilc = 1:nlc
    selected = row_ilc_ == ilc;
    quarter = row_quarter_(selected, :);
    m0_values = row_M0_(selected);
    for iside = 1:2
      qcolumn = 2 * iside;
      selected = ~isnan(quarter(:, qcolumn));
      if ~any(selected)
        continue
      end
      moment_component = (Mi(ilc) + Mj(ilc)) / lm(im);
      m0_component = 2 * M0_total(ilc) / lm(im);
      row_component = 2 * m0_values(selected) / lm(im);
      if iside == 1
        correction = sum(quarter(selected, qcolumn) - row_component);
        stress.Q(im, 1, ilc) = moment_component + m0_component ...
          + correction;
      else
        correction = sum(quarter(selected, qcolumn) + row_component);
        stress.Q(im, 2, ilc) = -moment_component - m0_component ...
          + correction;
      end
    end
  end
end

return
end