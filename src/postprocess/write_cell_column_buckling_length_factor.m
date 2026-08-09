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
bkinfo = result.bkinfo;

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
iccc = 1:nnc;
irow = 0;

for i = 1:nstory
  ist = nstory - i + 1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        % SS7互換: 断面算定対象外の柱（RC柱等）は選択から除外
        inc = iccc(idnm2story == ist & idnm2x(:,1) == ix ...
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

        % X方向（列5-13）[剛比: mm3→cm3]
        body{irow,5} = sprintf('%.2f', bkinfo.IcLc(inc) / 1000);
        body{irow,6} = sprintf('%.2f', bkinfo.sumIcTop(inc) / 1000);
        body{irow,7} = sprintf('%.2f', bkinfo.sumIgTopX(inc) / 1000);
        body{irow,8} = sprintf('%.3f', bkinfo.GAx(inc));
        body{irow,9} = sprintf('%.2f', bkinfo.sumIcBot(inc) / 1000);
        body{irow,10} = sprintf('%.2f', bkinfo.sumIgBotX(inc) / 1000);
        body{irow,11} = sprintf('%.3f', bkinfo.GBx(inc));
        body{irow,12} = sprintf('%.3f', bkinfo.kcxRaw(inc));
        body{irow,13} = sprintf('%.3f', bkinfo.kcx(inc));

        % Y方向（列14-22）[剛比: mm3→cm3]
        body{irow,14} = sprintf('%.2f', bkinfo.IcLc(inc) / 1000);
        body{irow,15} = sprintf('%.2f', bkinfo.sumIcTop(inc) / 1000);
        body{irow,16} = sprintf('%.2f', bkinfo.sumIgTopY(inc) / 1000);
        body{irow,17} = sprintf('%.3f', bkinfo.GAy(inc));
        body{irow,18} = sprintf('%.2f', bkinfo.sumIcBot(inc) / 1000);
        body{irow,19} = sprintf('%.2f', bkinfo.sumIgBotY(inc) / 1000);
        body{irow,20} = sprintf('%.3f', bkinfo.GBy(inc));
        body{irow,21} = sprintf('%.3f', bkinfo.kcyRaw(inc));
        body{irow,22} = sprintf('%.3f', bkinfo.kcy(inc));
      end
    end
  end
end

% 空行を削除
body = body(1:irow, :);

return
end
