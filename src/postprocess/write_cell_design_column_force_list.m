function [dcflhead, dcflbody] = ...
  write_cell_design_column_force_list(com, result, icase)
%writeSectionProperties - Write section properties

% 定数
nc = com.nmec;
% nsc = com.nsecc;
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
dfn_all = result.dfn;

% ID変換
idnm2sc = column.idsecc(nominal_column.idmec(:,1));
idnm2x = column.idx(nominal_column.idmec(:,1),1);
idnm2y = column.idy(nominal_column.idmec(:,1),1);
idnm2z = column.idz(nominal_column.idmec(:,1),1);
idnm2story = column.idstory(nominal_column.idmec(:,1),1);
idnm2mc = nominal_column.idmec;
idnmc2nm = nominal_column.idnominal;
idmc2m = column.idme;

% 場合分け
if icase == 1
  ilcset = 1;
  label = {'L'};
else
  ilcset = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN];
  label = {'L+Ex', 'L-Ex', 'L+Ey', 'L-Ey'};
end
nlc = length(ilcset);
maxlc = max(ilcset);

% --- 柱設計応力表 ---
dcflhead = { ...
  '層', 'X軸', 'Y軸', '符号', 'ケース', '部材長', ...
  '軸力', '曲げx', '', '', 'せん断x', '', ...
  '曲げy', '', '', 'せん断y', ''; ...
  '', '', '', '', '', '', ...
  '', '柱頭', '中央', '柱脚', '柱頭', '柱脚', ...
  '柱頭', '中央', '柱脚', '柱頭', '柱脚'; ...
  '', '', '', '', '', 'mm',	...
  'kN', 'kNm', 'kNm', 'kNm', 'kN', 'kN', ...
  'kNm', 'kNm', 'kNm', 'kN', 'kN'};
ncol = size(dcflhead,2);
dcflbody = cell(0,ncol);
if nnc==0 || isempty(lm_nominal)
  return
end
if isempty(dfn_all) || size(dfn_all,3)<maxlc
  return
end
dfn = dfn_all(:,:,ilcset);
rows = cell(nc*nlc,ncol);
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
        ic1 = idnm2mc(inc,idsub(1)); im1 = idmc2m(ic1);
        ic2 = idnm2mc(inc,idsub(2)); im2 = idmc2m(ic2);

        for ilc=1:nlc
          irow = irow+1;
          if ilc==1
            rows{irow,1} = column.floor_name{ic1};
            rows{irow,2} = column.coord_name{ic1,1};
            rows{irow,3} = column.coord_name{ic1,2};
            isc = column.idsecc(ic1);
            rows{irow,4} = [secc.subindex{isc} secc.name{isc}];
            rows{irow,6} = sprintf('%.0f', lm_nominal(im1));
          end
          rows{irow,5} = label{ilc};
          rows{irow,7} = sprintf('%.0f', dfn(inm,1,ilc)*1.d-3);
          rows{irow,8} = sprintf('%.0f', dfn(inm,11,ilc)*1.d-6);
          rows{irow,9} = '';
          rows{irow,10} = sprintf('%.0f', -dfn(inm,5,ilc)*1.d-6);
          rows{irow,11} = sprintf('%.0f', dfn(inm,9,ilc)*1.d-3);
          rows{irow,12} = sprintf('%.0f', dfn(inm,3,ilc)*1.d-3);
          rows{irow,13} = sprintf('%.0f', dfn(inm,12,ilc)*1.d-6);
          rows{irow,14} = '';
          rows{irow,15} = sprintf('%.0f', -dfn(inm,6,ilc)*1.d-6);
          rows{irow,16} = sprintf('%.0f', -dfn(inm,8,ilc)*1.d-3);
          rows{irow,17} = sprintf('%.0f', -dfn(inm,2,ilc)*1.d-3);
        end
      end
    end
  end
end

if irow==0
  dcflbody = cell(0,ncol);
else
  dcflbody = rows(1:irow,:);
end
return
end
