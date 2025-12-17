function [dciflhead, dciflbody] = ...
  write_cell_design_column_init_force_list(com, result)
%writeSectionProperties - Write section properties

% 定数
nc = com.nmec;
nnc = com.num.nominal_column;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nstory = com.nstory;
dfn0_all = result.dfn0;
nlc = size(dfn0_all,3);

% 共通配列
nominal_column = com.nominal.column;
column = com.member.column;
secc = com.section.column;
lm_nominal = result.lm_nominal;

% ID変換
idnmc2x = column.idx(nominal_column.idmec(:,1),1);
idnmc2y = column.idy(nominal_column.idmec(:,1),1);
idnmc2z = column.idz(nominal_column.idmec(:,1),1);
idnmc2story = column.idstory(nominal_column.idmec(:,1),1);
idnmc2mc = nominal_column.idmec;
idnmc2nm = nominal_column.idnominal;
idmc2m = column.idme;

% --- 柱設計応力表 ---
dciflhead = cell(3,20);
dciflhead(1,1:18) = { ...
'階', 'X軸', 'Y軸', '符号', 'ケース', ...
'部材長', '軸力', '', '曲げx', '', ...
'', 'せん断x', '', '', '曲げy', ...
'', '', 'せん断y'};

dciflhead(2,6:20) = { ...
'', '柱頭', '柱脚', '柱頭', '中央' ...
'柱脚', '柱頭', '中央', '柱脚', '柱頭' ...
'中央', '柱脚', '柱頭', '中央', '柱脚'};

dciflhead(3,6:20) = { ...
'mm', 'kN', 'kN', 'kNm', 'kNm' ...
'kNm', 'kN', 'kN', 'kN', 'kNm' ...
'kNm', 'kNm', 'kN', 'kN', 'kN'};

ncol = size(dciflhead,2);
dciflbody = cell(0,ncol);
if nnc==0 || isempty(lm_nominal) || isempty(dfn0_all) || nlc==0
  return
end
dfn0 = dfn0_all;
dciflbody = cell(nc*nlc,ncol);
iccc = 1:nnc;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        % --- 該当ID検索 ---
        inc = iccc(idnmc2story==ist ...
          & idnmc2x(:,1)==ix & idnmc2y(:,1)==iy & idnmc2z(:,1)==iz);
        if isempty(inc)
          continue
        end
        inm = idnmc2nm(inc);

        % --- 箇所ごとの部材番号 ---
        idsub = nominal_column.idsub(inc,:);
        ic1 = idnmc2mc(inc,idsub(1)); im1 = idmc2m(ic1);
        ic2 = idnmc2mc(inc,idsub(2)); im2 = idmc2m(ic2);

        % --- 表書き出し ---
        for ilc=1:nlc
          irow = irow+1;
          if ilc==1
            dciflbody{irow,1} = column.floor_name{ic1};
            dciflbody{irow,2} = column.coord_name{ic1,1};
            dciflbody{irow,3} = column.coord_name{ic1,2};
            isc = column.idsecc(ic1);
            dciflbody{irow,4} = [secc.subindex{isc} secc.name{isc}];
            dciflbody{irow,6} = sprintf('%.0f', lm_nominal(im1));
          end
          dciflbody{irow,5} = PRM.load_case_name(ilc);
          % 軸力
          dciflbody{irow,7} = sprintf('%.2f', dfn0(inm,1,ilc)*1.d-3);
          dciflbody{irow,8} = sprintf('%.2f', -dfn0(inm,7,ilc)*1.d-3);
          % 曲げx
          dciflbody{irow,9} = sprintf('%.2f', dfn0(inm,11,ilc)*1.d-6);
          dciflbody{irow,10} = '';
          dciflbody{irow,11} = sprintf('%.2f', -dfn0(inm,5,ilc)*1.d-6);
          % せん断x
          dciflbody{irow,12} = sprintf('%.2f', dfn0(inm,9,ilc)*1.d-3);
          dciflbody{irow,13} = '';
          dciflbody{irow,14} = sprintf('%.2f', dfn0(inm,3,ilc)*1.d-3);
          % 曲げy
          dciflbody{irow,15} = sprintf('%.2f', dfn0(inm,12,ilc)*1.d-6);
          dciflbody{irow,16} = '';
          dciflbody{irow,17} = sprintf('%.2f', -dfn0(inm,6,ilc)*1.d-6);
          % せん断y
          dciflbody{irow,18} = sprintf('%.2f', -dfn0(inm,8,ilc)*1.d-3);
          dciflbody{irow,19} = '';
          dciflbody{irow,20} = sprintf('%.2f', -dfn0(inm,2,ilc)*1.d-3);
        end
      end
    end
  end
end
if irow==0
  dciflbody = cell(0,ncol);
else
  dciflbody = dciflbody(1:irow,:);
end
return
end
