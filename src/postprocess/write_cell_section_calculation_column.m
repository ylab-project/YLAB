function sccbody = write_cell_section_calculation_column(com, result)

% 定数
nc = com.nmec;
nsc = com.nsecc;
nnc = com.num.nominal_column;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nlc = com.nlc;
nstory = com.nstory;
mb = 11;
ncol = 14;

% 共通配列
column = com.member.column;
nominal_column = com.nominal.column;
secc = com.section.column;
dfn = result.dfn;
fbn = result.fbn;
fcn = result.fcn;
A = result.msprop.A;
Asy = result.msprop.Asy;
Asz = result.msprop.Asz;
Iy = result.msprop.Iy;
Iz = result.msprop.Iz;
Zy = result.msprop.Zy;
Zz = result.msprop.Zz;
kcx = result.kcx;
kcy = result.kcy;
lambday = result.lambday;
lambdaz = result.lambdaz;
ration = abs(result.ration);
lfcx = result.lf.columnx;
lfcy = result.lf.columny;
lrcx = result.lr.columnx;
lrcy = result.lr.columny;
mtype = com.member.property.type;
lm_nominal = result.lm_nominal;
cri_all = result.cri;
crj_all = result.crj;
csi_all = result.csi;
csj_all = result.csj;

if isempty(ration)
  % nnc==0 || isempty(dfn) || isempty(fbn) ...
  %   || isempty(fcn) || isempty(A) || isempty(Asy) || isempty(Asz) ...
  %   || isempty(Iy) || isempty(Iz) || isempty(Zy) || isempty(Zz) ...
  %   || isempty(kcx) || isempty(kcy) || isempty(lambday) ...
  %   || isempty(lambdaz) || isempty(ration) || isempty(lfcx) ...
  %   || isempty(lfcy) || isempty(lrcx) || isempty(lrcy) ...
  %   || isempty(cri_all) || isempty(crj_all) || isempty(csi_all) ...
  %   || isempty(csj_all)
  sccbody = cell(0,ncol);
  return
end

% 断面2次半径
% lm = result.lm;
iy_ = sqrt(Iy./A);
iz_ = sqrt(Iz./A);
lrm = lm_nominal;
lrm(mtype==PRM.COLUMN) = lrm(mtype==PRM.COLUMN)...
  -max([sum(lrcx,2) sum(lrcy,2)],[],2);

% 柱許容応力度比
cri = reshape(cri_all,[],nlc)+1; % 柱i端曲げ応力度の検定
crj = reshape(crj_all,[],nlc)+1; % 柱j端曲げ応力度の検定
csi = reshape(csi_all,nnc,nlc)+1; % 柱i端せん断応力度の検定
csj = reshape(csj_all,nnc,nlc)+1; % 柱j端せん断応力度の検定

% ID変換
idnm2sc = column.idsecc(nominal_column.idmec(:,1));
idnm2x = column.idx(nominal_column.idmec(:,1),1);
idnm2y = column.idy(nominal_column.idmec(:,1),1);
idnm2z = column.idz(nominal_column.idmec(:,1),1);
idnm2story = column.idstory(nominal_column.idmec(:,1),1);
idnm2mc = nominal_column.idmec;
idnmc2nm = nominal_column.idnominal;
idmc2m = column.idme;

% --- S柱断面算定表 ---
sccbody = cell(mb*nnc,ncol);
iccc = 1:nnc;
irow1 = 0;
irow2 = 0;
for isc = 1:nsc
  for i = 1:nstory
    ist = nstory-i+1;
    for iy = 1:nbly
      for ix = 1:nblx
        for iz = 1:nblz
          inc = iccc(idnm2story==ist & idnm2sc==isc ...
            & idnm2x(:,1)==ix & idnm2y(:,1)==iy & idnm2z(:,1)==iz);
          if isempty(inc)
            continue
          end
          inm = idnmc2nm(inc);

          % --- 最大ケースの判定 ---
          [~, ilx] = max(cri(inc,[1 2 3]));
          [~, ily] = max(cri(inc,[1 4 5]));
          [~, jlx] = max(crj(inc,[1 2 3]));
          [~, jly] = max(crj(inc,[1 4 5]));
          [~, isx] = max(csi(inc,[1 2 3]));
          [~, isy] = max(csi(inc,[1 4 5]));
          [~, jsx] = max(csj(inc,[1 2 3]));
          [~, jsy] = max(csj(inc,[1 4 5]));
          if ily>1
            ily = ily+2;
          end
          if jly>1
            jly = jly+2;
          end
          if isy>1
            isy = isy+2;
          end
          if jsy>1
            jsy = jsy+2;
          end

          % --- 箇所ごとの部材番号 ---
          idsub = nominal_column.idsub(inc,:);
          ic1 = idnm2mc(inc,idsub(1)); im1 = idmc2m(ic1);
          ic2 = idnm2mc(inc,idsub(2)); im2 = idmc2m(ic2);

          %---
          irow1 = irow1+1;
          sccbody{irow1,1} = sprintf('[%s]', ...
            [secc.subindex{isc} secc.name{isc}]);
          sccbody{irow1,2} = column.floor_name{ic1};
          sccbody{irow1,3} = sprintf('%s-%s', ...
            column.coord_name{ic1,1}, column.coord_name{ic2,2});

          %---
          irow2 = irow2+1;
          sccbody(irow2,5:13) = {...
            '位置','NL', ...
            'ML''', 'QL', '[部材]', 'ケース', 'N', 'M', ...
            'Q'};

          %---
          irow2 = irow2+1;
          sccbody{irow2,4} = '<X>柱頭';
          sccbody{irow2,5} = sprintf('%.0f', lfcx(ic2,2));
          % sccbody{irow2,6} = sprintf('%.0f', -rs(im1,7,1)*1.d-3);
          sccbody{irow2,6} = sprintf('%.0f', -dfn(inm,7,1)*1.d-3);
          sccbody{irow2,7} = sprintf('%.0f', dfn(inm,11,1)*1.d-6);
          sccbody{irow2,8} = sprintf('%.0f', dfn(inm,9,1)*1.d-3);
          sccbody{irow2,10} = PRM.load_case_name(jlx);
          % sccbody{irow2,11} = sprintf('%.0f', -rs(im1,7,jlx)*1.d-3);
          sccbody{irow2,11} = sprintf('%.0f', -dfn(inm,7,jlx)*1.d-3);
          sccbody{irow2,12} = sprintf('%.0f', dfn(inm,11,jlx)*1.d-6);
          sccbody{irow2,13} = sprintf('%.0f', dfn(inm,9,jlx)*1.d-3);

          %---
          irow1 = irow1+1;
          % 断面寸法

          %---
          irow1 = irow1+1;
          sccbody{irow1,1} = '部材長';
          sccbody{irow1,2} = sprintf('%.0f', lm_nominal(im1));

          %---
          irow2 = irow2+1;
          sccbody{irow2,4} = '柱脚';
          sccbody{irow2,5} = sprintf('%.0f', lfcx(ic1,1));
          % sccbody{irow2,6} = sprintf('%.0f', rs(im1,1,1)*1.d-3);
          sccbody{irow2,6} = sprintf('%.0f', dfn(inm,1,1)*1.d-3);
          sccbody{irow2,7} = sprintf('%.0f', -dfn(inm,5,1)*1.d-6);
          sccbody{irow2,8} = sprintf('%.0f', dfn(inm,3,1)*1.d-3);
          sccbody{irow2,10} = PRM.load_case_name(ilx);
          % sccbody{irow2,11} = sprintf('%.0f', rs(im1,1,ilx)*1.d-3);
          sccbody{irow2,11} = sprintf('%.0f', dfn(inm,1,ilx)*1.d-3);
          sccbody{irow2,12} = sprintf('%.0f', -dfn(inm,5,ilx)*1.d-6);
          sccbody{irow2,13} = sprintf('%.0f', dfn(inm,3,ilx)*1.d-3);

          %---
          irow1 = irow1+1;
          sccbody{irow1,2} = '<X>';
          sccbody{irow1,3} = '<Y>';

          %---
          irow2 = irow2+1;          
          sccbody{irow2,4} = '<Y>柱頭';
          sccbody{irow2,5} = sprintf('%.0f', lfcy(ic2,2));
          % sccbody{irow2,6} = sprintf('%.0f', -rs(im1,7,1)*1.d-3);
          sccbody{irow2,6} = sprintf('%.0f', -dfn(inm,7,1)*1.d-3);
          sccbody{irow2,7} = sprintf('%.0f', dfn(inm,12,1)*1.d-6);
          sccbody{irow2,8} = sprintf('%.0f', -dfn(inm,8,1)*1.d-3);
          sccbody{irow2,10} = PRM.load_case_name(jly);
          % sccbody{irow2,11} = sprintf('%.0f', -rs(im1,7,jly)*1.d-3);
          sccbody{irow2,11} = sprintf('%.0f', -dfn(inm,7,jly)*1.d-3);
          sccbody{irow2,12} = sprintf('%.0f', dfn(inm,12,jly)*1.d-6);
          sccbody{irow2,13} = sprintf('%.0f', -dfn(inm,8,jly)*1.d-3);

          %---
          irow1 = irow1+1;
          sccbody{irow1,1} = 'Lk/h';
          sccbody{irow1,2} = sprintf('%.2f', kcx(ic1));
          sccbody{irow1,3} = sprintf('%.2f', kcy(ic1));

          %---
          irow2 = irow2+1;
          sccbody{irow2,4} = '柱脚';
          sccbody{irow2,5} = sprintf('%.0f', lfcy(ic1,1));
          % sccbody{irow2,6} = sprintf('%.0f', rs(im1,1,1)*1.d-3);
          sccbody{irow2,6} = sprintf('%.0f', dfn(inm,1,1)*1.d-3);
          sccbody{irow2,7} = sprintf('%.0f', -dfn(inm,6,1)*1.d-6);
          sccbody{irow2,8} = sprintf('%.0f', -dfn(inm,2,1)*1.d-3);
          sccbody{irow2,10} = PRM.load_case_name(ily);
          % sccbody{irow2,11} = sprintf('%.0f', rs(im1,1,ily)*1.d-3);
          sccbody{irow2,11} = sprintf('%.0f', dfn(inm,1,ily)*1.d-3);
          sccbody{irow2,12} = sprintf('%.0f', -dfn(inm,6,ily)*1.d-6);
          sccbody{irow2,13} = sprintf('%.0f', -dfn(inm,2,ily)*1.d-3);

          %---
          irow1 = irow1+1;
          sccbody{irow1,1} = 'Lk';
          sccbody{irow1,2} = sprintf('%.0f', kcx(ic1)*lrm(im1));
          sccbody{irow1,3} = sprintf('%.0f', kcy(ic1)*lrm(im1));

          %---
          irow2 = irow2+1;
          sccbody(irow2,5:14) = {...
            'Z', 'A', 'Aw', 'fb', 'σc/fc', 'σbx/fb', ...
            'σby/fb', 'TOTAL', 'τ/fs', '組合せ'};

          %---
          irow1 = irow1+1;
          sccbody{irow1,1} = 'iy';
          sccbody{irow1,2} = sprintf('%.2f', iy_(im1)*1.d-1);
          sccbody{irow1,3} = sprintf('%.2f', iz_(im1)*1.d-1);

          %---
          irow2 = irow2+1;
          sccbody{irow2,4} = '<X>柱頭';
          sccbody{irow2,5} = sprintf('%.0f', Zy(im2)*1.d-3);
          sccbody{irow2,6} = sprintf('%.0f', A(im2)*1.d-2);
          sccbody{irow2,7} = sprintf('%.0f', Asy(im2)*1.d-2);
          sccbody{irow2,8} = sprintf('%.0f', fbn(inm,2,jlx));
          sccbody{irow2,9} = sprintf('%.2f', ration(inm,7,jlx));
          sccbody{irow2,10} = sprintf('%.2f', ration(inm,11,jlx));
          sccbody{irow2,11} = sprintf('%.2f', ration(inm,12,jlx));
          sccbody{irow2,12} = sprintf('%.2f', ...
            ration(inm,7,jlx)+ration(inm,11,jlx)+ration(inm,12,jlx));
          sccbody{irow2,13} = sprintf('%.2f', ration(inm,9,jsx));

          %---
          irow1 = irow1+1;
          sccbody{irow1,1} = 'λ';
          sccbody{irow1,2} = sprintf('%.1f', lambday(im1));
          sccbody{irow1,3} = sprintf('%.1f', lambdaz(im1));

          %---
          irow2 = irow2+1;
          sccbody{irow2,4} = '柱脚';
          sccbody{irow2,5} = sprintf('%.0f', Zy(im1)*1.d-3);
          sccbody{irow2,6} = sprintf('%.0f', A(im1)*1.d-2);
          sccbody{irow2,7} = sprintf('%.0f', Asy(im1)*1.d-2);
          sccbody{irow2,8} = sprintf('%.0f', fbn(inm,1,ilx));
          sccbody{irow2,9} = sprintf('%.2f', ration(inm,1,ilx));
          sccbody{irow2,10} = sprintf('%.2f', ration(inm,5,ilx));
          sccbody{irow2,11} = sprintf('%.2f', ration(inm,6,ilx));
          sccbody{irow2,12} = sprintf('%.2f', ...
            ration(inm,1,ilx)+ration(inm,5,ilx)+ration(inm,6,ilx));
          sccbody{irow2,13} = sprintf('%.2f', ration(inm,9,isx));

          %---
          irow1 = irow1+1;
          sccbody{irow1,1} = 'fcL';
          sccbody{irow1,2} = sprintf('%.0f', fcn(inm,1,1));

          %---
          irow2 = irow2+1;
          sccbody{irow2,4} = '<Y>柱頭';
          sccbody{irow2,5} = sprintf('%.0f', Zy(im2)*1.d-3);
          sccbody{irow2,6} = sprintf('%.0f', A(im2)*1.d-2);
          sccbody{irow2,7} = sprintf('%.0f', Asz(im2)*1.d-2);
          sccbody{irow2,8} = sprintf('%.0f', fbn(inm,2,jly));
          sccbody{irow2,9} = sprintf('%.2f', ration(inm,7,jly));
          sccbody{irow2,10} = sprintf('%.2f', ration(inm,11,jly));
          sccbody{irow2,11} = sprintf('%.2f', ration(inm,12,jly));
          sccbody{irow2,12} = sprintf('%.2f', ...
            ration(inm,7,jly)+ration(inm,11,jly)+ration(inm,12,jly));
          sccbody{irow2,13} = sprintf('%.2f', ration(inm,8,jsy));

          %---
          irow1 = irow1+1;
          sccbody{irow1,1} = 'fcS';
          sccbody{irow1,2} = sprintf('%.0f', fcn(inm,1,2));

          %---
          irow2 = irow2+1;
          sccbody{irow2,4} = '柱脚';
          sccbody{irow2,5} = sprintf('%.0f', Zz(im1)*1.d-3);
          sccbody{irow2,6} = sprintf('%.0f', A(im1)*1.d-2);
          sccbody{irow2,7} = sprintf('%.0f', Asy(im1)*1.d-2);
          sccbody{irow2,8} = sprintf('%.0f', fbn(inm,1,ily));
          sccbody{irow2,9} = sprintf('%.2f', ration(inm,1,ily));
          sccbody{irow2,10} = sprintf('%.2f', ration(inm,5,ily));
          sccbody{irow2,11} = sprintf('%.2f', ration(inm,6,ily));
          sccbody{irow2,12} = sprintf('%.2f', ...
            ration(inm,1,ily)+ration(inm,5,ily)+ration(inm,6,ily));
          sccbody{irow2,13} = sprintf('%.2f', ration(inm,8,isy));
        end
      end
    end
  end
end
return
end
