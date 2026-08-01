function [head, body] = ...
  write_cell_allowable_stress_ratio_column_by_case(com, result, ilc)
%write_cell_allowable_stress_ratio_column_by_case - S柱ケース別一覧生成
%
%   [head, body] = ...
%     write_cell_allowable_stress_ratio_column_by_case(com, result, ilc)
%   は、S柱検定比一覧(ケース・部材ごと)の1ケース分を生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (cri/crj/ration)
%     ilc    - 出力する荷重組合せケース番号
%
%   出力引数:
%     head - ヘッダ部セル配列 [3×13]
%     body - データ部セル配列 [nrow×13]

nnc = com.num.nominal_column;
nlc = com.nlc;
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
ncol = 13;

nominal_column = com.nominal.column;
column = com.member.column;
secc = com.section.column;

head = cell(3, ncol);
head(1, :) = {'階', 'X軸', 'Y軸', '符号', 'M', '', '', ...
  'Q', '', '', '', '組合せ', ''};
head(2, 5:13) = {'柱頭', '中央', '柱脚', '柱頭', '', ...
  '柱脚', '', '柱頭', '柱脚'};
head(3, 8:11) = {'x', 'y', 'x', 'y'};

body = cell(0, ncol);
if nnc == 0 || ilc > nlc
  return
end
if isempty(result.cri) || isempty(result.crj) || isempty(result.ration)
  return
end
if size(result.ration, 2) < 16 || size(result.ration, 3) < ilc
  return
end

cri = reshape(result.cri, [], nlc) + 1;
crj = reshape(result.crj, [], nlc) + 1;
ration = result.ration;

idnm2mc = nominal_column.idmec;
idnmc2nm = nominal_column.idnominal;
idnm2sc = column.idsecc(idnm2mc(:, 1));
idnm2story = column.idstory(idnm2mc(:, 1), 1);
idnm2x = column.idx(idnm2mc(:, 1), 1);
idnm2y = column.idy(idnm2mc(:, 1), 1);
idnm2z = column.idz(idnm2mc(:, 1), 1);
is_as = nominal_column.is_allowable_stress;

body = cell(nnc, ncol);
iccc = 1:nnc;
irow = 0;
for ist = nstory:-1:1
  for ix = 1:nblx
    for iy = 1:nbly
      for iz = 1:nblz
        inc_list = iccc(idnm2story == ist & idnm2x == ix ...
          & idnm2y == iy & idnm2z == iz & is_as);
        for k = 1:numel(inc_list)
          add_row(inc_list(k));
        end
      end
    end
  end
end
body = body(1:irow, :);

return

  function add_row(inc)
  %add_row - 1名目柱のケース別検定比を body に追加する
    inm = idnmc2nm(inc);
    isc = idnm2sc(inc);
    irow = irow + 1;
    body{irow, 1} = column.floor_name{idnm2mc(inc, 1)};
    body{irow, 2} = column.coord_name{idnm2mc(inc, 1), 1};
    body{irow, 3} = column.coord_name{idnm2mc(inc, 1), 2};
    body{irow, 4} = make_section_symbol(secc, isc);
    body{irow, 5} = format_ratio(crj(inc, ilc));
    body{irow, 6} = '';
    body{irow, 7} = format_ratio(cri(inc, ilc));
    body{irow, 8} = format_ratio(abs(ration(inm, 9, ilc)));
    body{irow, 9} = format_ratio(abs(ration(inm, 8, ilc)));
    body{irow, 10} = format_ratio(abs(ration(inm, 3, ilc)));
    body{irow, 11} = format_ratio(abs(ration(inm, 2, ilc)));
    body{irow, 12} = format_ratio(abs(ration(inm, 16, ilc)));
    body{irow, 13} = format_ratio(abs(ration(inm, 15, ilc)));
  end

  function s = format_ratio(v)
  %format_ratio - SS7互換の小数2桁切り上げ文字列にする
    s = sprintf('%.2f', ceil(v * 100) / 100);
  end
end
