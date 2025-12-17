function [cblhead, cblbody] = write_cell_column_buckling_length(com, result)
%write_cell_column_buckling_length - Write column buckling length data

% 定数
nc = com.nmec;
nnc = com.num.nominal_column;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nstory = com.nstory;

% 共通配列
nominal_column = com.nominal.column;
column = com.member.column;
secc = com.section.column;
lm_nominal = result.lm_nominal;

% 断面特性
msprop = result.msprop;
iy = sqrt(msprop.Iy./msprop.A);
iz = sqrt(msprop.Iz./msprop.A);

% 座屈長さ係数と座屈長さ
kcx = result.kcx;
kcy = result.kcy;
% lkx = result.lkx;
% lky = result.lky;
lambday = result.lambday;
lambdaz = result.lambdaz;

% 最大横補剛間隔
lbmax = result.lb(com.member.property.type==PRM.COLUMN,3);

% ID変換
idnm2sc = column.idsecc(nominal_column.idmec(:,1));
idnm2x = column.idx(nominal_column.idmec(:,1),1);
idnm2y = column.idy(nominal_column.idmec(:,1),1);
idnm2z = column.idz(nominal_column.idmec(:,1),1);
idnm2story = column.idstory(nominal_column.idmec(:,1),1);
idnm2mc = nominal_column.idmec;
idnmc2nm = nominal_column.idnominal;
idmc2m = column.idme;

% --- 柱座屈長さ表 ---
cblhead = { ...
  '階', 'X軸', 'Y軸', '符号', '部材長 L', '', '最大横補剛間隔Lb', '', ...
  '座屈長さ係数 K', '', '座屈長さ Lk', '', '細長比 λ', ''; ...
  '', '', '', '', 'x方向', 'y方向', 'x方向', 'y方向', ...
  'x方向', 'y方向', 'x方向', 'y方向', 'x方向', 'y方向'; ...
  '', '', '', '', 'mm', 'mm', 'mm', 'mm', ...
  '', '', 'mm', 'mm', '', ''};

cblbody = cell(nnc,14);
iccc = 1:nnc;
irow = 0;

for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        inc = iccc(idnm2story==ist ...
          & idnm2x(:,1)==ix & idnm2y(:,1)==iy & idnm2z(:,1)==iz);
        if isempty(inc)
          continue
        end
        inm = idnmc2nm(inc);

        % --- 箇所ごとの部材番号 ---
        idsub = nominal_column.idsub(inc,:);
        ic1 = idnm2mc(inc,idsub(1)); 
        im1 = idmc2m(ic1);

        irow = irow+1;
        cblbody{irow,1} = column.floor_name{ic1};
        cblbody{irow,2} = column.coord_name{ic1,1};
        cblbody{irow,3} = column.coord_name{ic1,2};
        isc = column.idsecc(ic1);
        cblbody{irow,4} = [secc.subindex{isc} secc.name{isc}];
        
        % 部材長（x方向、y方向）
        cblbody{irow,5} = sprintf('%.0f', lm_nominal(im1));
        cblbody{irow,6} = sprintf('%.0f', lm_nominal(im1));
        
        % 最大横補剛間隔（x方向、y方向）
        lbmax_val = lbmax(inc);
        cblbody{irow,7} = sprintf('%.0f', lbmax_val);
        cblbody{irow,8} = sprintf('%.0f', lbmax_val);
        
        % 座屈長さ係数（x方向、y方向）
        % cblbody{irow,9} = sprintf('%.3f', kcx(im1));
        % cblbody{irow,10} = sprintf('%.3f', kcy(im1));
        
        % 座屈長さ（x方向、y方向）
        % cblbody{irow,11} = sprintf('%.0f', lkx(im1));
        % cblbody{irow,12} = sprintf('%.0f', lky(im1));
        
        % 細長比（x方向、y方向）
        cblbody{irow,13} = sprintf('%.1f', lambday);
        cblbody{irow,14} = sprintf('%.1f', lambdaz);
      end
    end
  end
end

return
end