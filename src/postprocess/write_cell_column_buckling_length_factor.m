function [head, body] = ...
  write_cell_column_buckling_length_factor(com, result)
%write_cell_column_buckling_length_factor - 柱座屈長さ係数の自動計算出力
%
%   [head, body] = ...
%     write_cell_column_buckling_length_factor(com, result) は、
%   柱座屈長さ係数 K の自動計算過程（柱剛比、上下端の Σ柱剛比・
%   Σ梁剛比、GA/GB、計算値・補正値）を符号別に集計したセル配列を
%   生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (bkinfo 等)
%
%   出力引数:
%     head - ヘッダ部セル配列 [3×22]
%     body - データ部セル配列 [nrow×22]

% 定数
nnc = com.num.nominal_column;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nstory = com.nstory;

% 共通配列
nominal_column = com.nominal.column;
column = com.member.column;
secc = com.section.column;
bkdir = {result.bkinfo.x, result.bkinfo.y};

% ID変換
idnm2mc = nominal_column.idmec;
idnm2x = column.idx(nominal_column.idmec(:,1), 1);
idnm2y = column.idy(nominal_column.idmec(:,1), 1);
idnm2z = column.idz(nominal_column.idmec(:,1), 1);
idnm2story = column.idstory(nominal_column.idmec(:,1), 1);

% ヘッダ（3行×22列）
head = { ...
  '階', 'X軸', 'Y軸', '符号', ...
  'X方向', '', '', '', '', '', '', '', '', ...
  'Y方向', '', '', '', '', '', '', '', ''; ...
  '', '', '', '', ...
  '柱剛比', '上', '', '', ...
  '下', '', '', 'Ｋ', '', ...
  '柱剛比', '上', '', '', ...
  '下', '', '', 'Ｋ', ''; ...
  '', '', '', '', ...
  '', 'Σ柱剛比', 'Σ梁剛比', 'ＧA', ...
  'Σ柱剛比', 'Σ梁剛比', 'ＧB', '計算', '補正', ...
  '', 'Σ柱剛比', 'Σ梁剛比', 'ＧA', ...
  'Σ柱剛比', 'Σ梁剛比', 'ＧB', '計算', '補正'};

% データ行
ncol = 22;
body = cell(nnc, ncol);
irow = 0;

for i = 1:nstory
  ist = nstory - i + 1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        % SS7互換: 断面算定対象外の柱（RC柱等）は選択から除外
        inc = find(idnm2story == ist & idnm2x(:,1) == ix ...
          & idnm2y(:,1) == iy & idnm2z(:,1) == iz ...
          & nominal_column.is_allowable_stress(:));
        if isempty(inc)
          continue
        end

        idsub = nominal_column.idsub(inc,:);
        ic1 = idnm2mc(inc, idsub(1));

        irow = irow + 1;

        % 共通列
        isc = column.idsecc(ic1);
        body(irow, 1:4) = {column.floor_name{ic1}, ...
          column.coord_name{ic1,1}, column.coord_name{ic1,2}, ...
          secc.full_name{isc}};

        % X方向（列5-13）とY方向（列14-22）[剛比: mm3→cm3]
        for idir = 1:2
          bk = bkdir{idir};
          c0 = 4 + 9*(idir-1);
          body{irow,c0+1} = sprintf('%.2f', bk.IcLc(inc) / 1000);
          body{irow,c0+2} = sprintf('%.2f', bk.sumIcTop(inc) / 1000);
          body{irow,c0+3} = sprintf('%.2f', bk.sumIgTop(inc) / 1000);
          body{irow,c0+4} = sprintf('%.3f', bk.GA(inc));
          body{irow,c0+5} = sprintf('%.2f', bk.sumIcBot(inc) / 1000);
          body{irow,c0+6} = sprintf('%.2f', bk.sumIgBot(inc) / 1000);
          body{irow,c0+7} = sprintf('%.3f', bk.GB(inc));
          body{irow,c0+8} = sprintf('%.3f', bk.kcRaw(inc));
          body{irow,c0+9} = sprintf('%.3f', bk.kcNominal(inc));
        end
      end
    end
  end
end

% 空行を削除
body = body(1:irow, :);

return
end
