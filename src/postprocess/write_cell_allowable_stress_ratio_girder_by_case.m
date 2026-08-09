function [head, body] = ...
  write_cell_allowable_stress_ratio_girder_by_case(com, result, ilc)
%write_cell_allowable_stress_ratio_girder_by_case - S梁ケース別一覧生成
%
%   [head, body] = ...
%     write_cell_allowable_stress_ratio_girder_by_case(com, result, ilc)
%   は、S梁検定比一覧(ケース・部材ごと)の1ケース分を生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (gri/grj/grc/gsi/gsj)
%     ilc    - 出力する荷重組合せケース番号
%
%   出力引数:
%     head - ヘッダ部セル配列 [4×10]
%     body - データ部セル配列 [nrow×10]

nng = com.num.nominal_girder;
nlc = com.nlc;
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
ncol = 10;

nominal_girder = com.nominal.girder;
girder = com.member.girder;
secg = com.section.girder;
gstype = secg.type;

head = cell(4, ncol);
head(1, :) = {'層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', ...
  'M', '', '', 'Q', ''};
head(2, 6:10) = {'左端', '中央', '右端', '左端', '右端'};

body = cell(0, ncol);
if nng == 0 || ilc > nlc
  return
end
if isempty(result.gri) || isempty(result.grj) || isempty(result.grc) ...
    || isempty(result.gsi) || isempty(result.gsj)
  return
end

gri = reshape(result.gri, [], nlc) + 1;
grj = reshape(result.grj, [], nlc) + 1;
grc = reshape(result.grc, [], nlc) + 1;
gsi = reshape(result.gsi, [], nlc) + 1;
gsj = reshape(result.gsj, [], nlc) + 1;

idmeg1 = nominal_girder.idmeg(:, 1);
idnmg2sg = girder.idsecg(idmeg1);
idnmg2stype = gstype(idnmg2sg);
idstory = nominal_girder.idstory;
idx = nominal_girder.idx;
idy = nominal_girder.idy;
idir = nominal_girder.idir;
is_as = nominal_girder.is_allowable_stress;

body = cell(nng, ncol);
iggg = 1:nng;
irow = 0;
for ist = nstory:-1:1
  for iy = 1:nbly
    for ix = 1:nblx
      mask = idstory == ist & idx(:, 1) == ix & idy(:, 1) == iy ...
        & idir == PRM.X & idnmg2stype == PRM.WFS & is_as;
      ing_list = iggg(mask);
      for k = 1:numel(ing_list)
        add_row(ing_list(k));
      end
    end
  end
  for ix = 1:nblx
    for iy = 1:nbly
      mask = idstory == ist & idx(:, 1) == ix & idy(:, 1) == iy ...
        & idir == PRM.Y & idnmg2stype == PRM.WFS & is_as;
      ing_list = iggg(mask);
      for k = 1:numel(ing_list)
        add_row(ing_list(k));
      end
    end
  end
end
body = body(1:irow, :);

return

  function add_row(ing)
  %add_row - 1名目梁のケース別検定比を body に追加する
    isg = idnmg2sg(ing);
    irow = irow + 1;
    body{irow, 1} = nominal_girder.story_name{ing};
    body{irow, 2} = nominal_girder.frame_name{ing};
    body{irow, 3} = nominal_girder.coord_name{ing, 1};
    body{irow, 4} = nominal_girder.coord_name{ing, 2};
    body{irow, 5} = secg.full_name{isg};
    body{irow, 6} = format_ratio(gri(ing, ilc));
    body{irow, 7} = format_ratio(grc(ing, ilc));
    body{irow, 8} = format_ratio(grj(ing, ilc));
    body{irow, 9} = format_ratio(gsi(ing, ilc));
    body{irow, 10} = format_ratio(gsj(ing, ilc));
  end

  function s = format_ratio(v)
  %format_ratio - SS7互換の小数2桁切り上げ文字列にする
    s = sprintf('%.2f', ceil(v * 100) / 100);
  end
end
