function [cblhead, cblbody] = write_cell_column_buckling_length( ...
  com, result)
%write_cell_column_buckling_length - 柱座屈長さ表のセル配列を生成する
%
%   [cblhead, cblbody] =
%     write_cell_column_buckling_length(com, result) は、
%   名目柱ごとに部材長・最大横補剛間隔・座屈長さ係数・座屈長さ・
%   細長比をまとめた表のヘッダとボディを出力用セル配列として返す。
%
%   入力引数:
%     com    - 共通データ構造体（部材・節点・断面情報）
%     result - 解析結果構造体（kcx/kcy, lkx/lky, lbc_nominal等）
%
%   出力引数:
%     cblhead - 表のヘッダ行セル配列 [3×14]
%     cblbody - 表のボディ行セル配列 [nrow×14]

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
if isfield(result, 'lm_bk_nominal_x')
  lm_nominal_x = result.lm_bk_nominal_x;
  lm_nominal_y = result.lm_bk_nominal_y;
else
  lm_nominal_x = result.lm_bk_nominal;
  lm_nominal_y = result.lm_bk_nominal;
end

% 座屈長さ係数・座屈長さ・細長比
kcx = result.kcx;
kcy = result.kcy;
lkx = result.lkx;
lky = result.lky;
lambday = result.lambday;
lambdaz = result.lambdaz;

% 最大横補剛間隔（方向別、控除後）
lbmax_x = result.lbc_nominal.bk.x.max;
lbmax_y = result.lbc_nominal.bk.y.max;

% ID変換
idnm2x = column.idx(nominal_column.idmec(:,1),1);
idnm2y = column.idy(nominal_column.idmec(:,1),1);
idnm2z = column.idz(nominal_column.idmec(:,1),1);
idnm2story = column.idstory(nominal_column.idmec(:,1),1);
idnm2mc = nominal_column.idmec;
idmc2m = column.idme;

% --- 柱座屈長さ表 ---
hdr1 = {'階', 'X軸', 'Y軸', '符号', '部材長 L', '', ...
  '最大横補剛間隔Lb', '', '座屈長さ係数 K', '', '座屈長さ Lk', ...
  '', '細長比 λ', ''};
hdr2 = {'', '', '', '', 'x方向', 'y方向', 'x方向', 'y方向', ...
  'x方向', 'y方向', 'x方向', 'y方向', 'x方向', 'y方向'};
hdr3 = {'', '', '', '', 'mm', 'mm', 'mm', 'mm', '', '', 'mm', ...
  'mm', '', ''};
cblhead = [hdr1; hdr2; hdr3];

cblbody = cell(nnc,14);
iccc = 1:nnc;
irow = 0;

for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        % SS7互換: 断面算定対象外の柱（RC柱等）は選択から除外
        inc = iccc(idnm2story==ist & idnm2x(:,1)==ix ...
          & idnm2y(:,1)==iy & idnm2z(:,1)==iz ...
          & nominal_column.is_allowable_stress(:));
        if isempty(inc)
          continue
        end

        % --- 箇所ごとの部材番号 ---
        idsub = nominal_column.idsub(inc,:);
        ic1 = idnm2mc(inc,idsub(1));
        im1 = idmc2m(ic1);

        irow = irow+1;
        cblbody{irow,1} = column.floor_name{ic1};
        cblbody{irow,2} = column.coord_name{ic1,1};
        cblbody{irow,3} = column.coord_name{ic1,2};
        isc = column.idsecc(ic1);
        cblbody{irow,4} = secc.full_name{isc};

        % 部材長（方向別の剛域控除後）
        cblbody{irow,5} = sprintf('%.0f', lm_nominal_x(im1));
        cblbody{irow,6} = sprintf('%.0f', lm_nominal_y(im1));

        % 最大横補剛間隔（x方向、y方向）
        cblbody{irow,7} = sprintf('%.0f', lbmax_x(inc));
        cblbody{irow,8} = sprintf('%.0f', lbmax_y(inc));

        % 座屈長さ係数（x方向、y方向）
        cblbody{irow,9} = sprintf('%.3f', kcx(ic1));
        cblbody{irow,10} = sprintf('%.3f', kcy(ic1));

        % 座屈長さ Lk（result.lkx/lkyを参照）
        cblbody{irow,11} = sprintf('%.0f', lkx(im1));
        cblbody{irow,12} = sprintf('%.0f', lky(im1, 1));

        % 細長比（x方向、y方向）
        cblbody{irow,13} = sprintf('%.1f', lambday(im1));
        cblbody{irow,14} = sprintf('%.1f', lambdaz(im1, 1));
      end
    end
  end
end

% 空行を削除
cblbody = cblbody(1:irow,:);

return
end
