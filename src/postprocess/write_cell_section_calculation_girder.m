function scgbody = write_cell_section_calculation_girder(com, result, options)

% 定数
% ng = com.nmeg;
nng = com.num.nominal_girder;
nblx = com.nblx;
nbly = com.nbly;
nlc = com.nlc;
nstory = com.nstory;
mb = 15;
ncol = 13;

% 共通配列
girder = com.member.girder;
nominal_girder = com.nominal.girder;
secg = com.section.girder;
lm_nominal = result.lm_nominal;
lfg = result.lf.girder;
lb = com.member.girder.stiffening_lb;
dfn = result.dfn;
Mc = result.Mc;
fbn = result.fbn;
fcn = result.fcn;
stn = result.stn;
stcn = result.stcn;
C = result.C;
Zf = result.msprop.Zyf;
if options.consider_web_at_girder_center
  Zc = result.msprop.Zy;
else
  Zc = result.msprop.Zyf;
end
if options.consider_web_at_girder_end
  Zij = result.msprop.Zys;  % スカラップ考慮版を使用
else
  Zij = result.msprop.Zyf;
end
A = result.msprop.A;
Aw = result.msprop.Aw;
lambda = result.lambdaz;
dangle = result.deflection_angle;
ration = abs(result.ration);
gri_all = result.gri;
grj_all = result.grj;
grc_all = result.grc;
gsi_all = result.gsi;
gsj_all = result.gsj;

if isempty(ration)
  % nng==0 || isempty(dfn) || isempty(fbn) ...
  %   || isempty(fcn) || isempty(Zf) || isempty(Zc) || isempty(Zij) ...
  %   || isempty(A) || isempty(Aw) || isempty(lambda) || isempty(dangle) ...
  %   || isempty(ration) || isempty(gri_all) || isempty(grj_all) ...
  %   || isempty(grc_all) || isempty(gsi_all) || isempty(gsj_all)
  scgbody = cell(0,ncol);
  return
end

% 梁許容応力度比
gri = reshape(gri_all,[],nlc)+1; % 梁i端曲げ応力度の検定
grj = reshape(grj_all,[],nlc)+1; % 梁j端曲げ応力度の検定
grc = reshape(grc_all,[],nlc)+1; % 梁中央曲げ応力度の検定
gsi = reshape(gsi_all,[],nlc)+1; % 梁i端せん断応力度の検定
gsj = reshape(gsj_all,[],nlc)+1; % 梁j端せん断応力度の検定

% ID変換
idnm2stype = girder.section_type(nominal_girder.idmeg(:,1));
idnm2sg = girder.idsecg(nominal_girder.idmeg(:,1));
idnm2dir = girder.idir(nominal_girder.idmeg(:,1),1);
idnm2x = girder.idx(nominal_girder.idmeg(:,1),1);
idnm2y = girder.idy(nominal_girder.idmeg(:,1),1);
idnm2story = girder.idstory(nominal_girder.idmeg(:,1),1);
idnm2mg = nominal_girder.idmeg;
idnmg2nm = nominal_girder.idnominal;
idmg2m = girder.idme;

% --- S梁断面算定表 ---
scgbody = cell(mb*nng,ncol);
iggg = 1:nng;
irow1 = 0;
irow2 = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for idir = 1:2
    for iy = 1:nbly
      for ix = 1:nblx
        ing = iggg(idnm2story==ist & idnm2x(:,1)==ix & ...
          idnm2y(:,1)==iy & idnm2dir==idir);
        if isempty(ing)
          continue
        end
        if idnm2stype(ing)~=PRM.WFS
          continue
        end
        if ~nominal_girder.is_allowable_stress(ing)
          continue
        end
        inm = idnmg2nm(ing);

        % --- 最大ケースの判定 ---
        isg = idnm2sg(ing);
        [grimax, ilc] = max(gri(ing,:));
        [grcmax, clc] = max(grc(ing,:));
        [grjmax, jlc] = max(grj(ing,:));

        % --- 箇所ごとの部材番号 ---
        idsub = nominal_girder.idsub(ing,:);
        ig1 = idnm2mg(ing,idsub(1)); im1 = idmg2m(ig1);
        ig2 = idnm2mg(ing,idsub(2)); im2 = idmg2m(ig2);
        igc = idnm2mg(ing,idsub(3)); imc = idmg2m(igc);

        %---
        irow1 = irow1+1;
        irow2 = irow2+1;
        scgbody(irow1,:) = {...
          '', '', '', '', '左端', 'JOINT', ...
          '中央', 'JOINT', '右端', '', '左端', '中央', '右端'};
        scgbody{irow1,1} = sprintf('[ %s ]', ...
          [secg.subindex{isg} secg.name{isg}]);

        %--
        irow1 = irow1+1; 
        scgbody{irow1,1} = girder.story_name{ig1};
        scgbody{irow1,2} = girder.frame_name{ig1};
        scgbody{irow1,3} = sprintf('%s %s', ...
          girder.coord_name{ig1,1}, girder.coord_name{ig2,2});
        scgbody{irow1,4} = '位置';
        scgbody{irow1,5} = sprintf('%.0f',lfg(ig1,1));
        scgbody{irow1,7} = sprintf('%.0f',lm_nominal(im1)/2);
        scgbody{irow1,9} = sprintf('%.0f',lfg(ig2,2));

        %--
        irow2 = irow2+1;
        scgbody{irow2,10} = 'ケース';
        scgbody{irow2,11} = PRM.load_case_name(ilc);
        scgbody{irow2,12} = PRM.load_case_name(clc);
        scgbody{irow2,13} = PRM.load_case_name(jlc);

        %--
        if stn(inm,1,1)~=0
          irow1 = irow1+1;
          scgbody{irow1,4} = 'NL';
          scgbody{irow1,5} = sprintf('%.0f', dfn(inm,1,1)*1.d-3);
          scgbody{irow1,9} = sprintf('%.0f', -dfn(inm,7,1)*1.d-3);
        end

        %---
        irow1 = irow1+1;
        scgbody{irow1,4} = 'ML''';
        scgbody{irow1,5} = sprintf('%.0f', -dfn(inm,5,1)*1.d-6);
        scgbody{irow1,7} = sprintf('%.0f', -Mc(imc,1)*1.d-6);
        scgbody{irow1,9} = sprintf('%.0f', dfn(inm,11,1)*1.d-6);

        %---
        irow2 = irow2+1;
        scgbody{irow2,10} = 'Lb';
        scgbody{irow2,11} = lb(ig1,1);
        scgbody{irow2,12} = lb(igc,3);
        scgbody{irow2,13} = lb(ig2,2);

        %---
        irow1 = irow1+1;
        scgbody{irow1,4} = 'QL';
        scgbody{irow1,5} = sprintf('%.0f', dfn(inm,3,1)*1.d-3);
        scgbody{irow1,9} = sprintf('%.0f', dfn(inm,9,1)*1.d-3);

        %---
        irow2 = irow2+1;
        scgbody{irow2,10} = 'C';
        scgbody{irow2,11} = sprintf('%.2f', C(ig1,1,ilc));
        scgbody{irow2,12} = sprintf('%.2f', C(igc,3,clc));
        scgbody{irow2,13} = sprintf('%.2f', C(ig2,2,jlc));

        %---
        irow1 = irow1+1;
        scgbody{irow1,4} = '[部材]';

        %---
        irow2 = irow2+1;
        scgbody{irow2,10} = 'fb';
        scgbody{irow2,11} = sprintf('%.0f', fbn(inm,1,ilc));
        scgbody{irow2,12} = sprintf('%.0f', fbn(inm,2,clc));
        scgbody{irow2,13} = sprintf('%.0f', fbn(inm,3,jlc));

        %---
        if any(stn(im1,[1 7],1)~=0)
          irow2 = irow2+1;
          scgbody{irow2,10} = 'fc';
          fci = fcn(inm,1,ilc);
          fcc = fcn(inm,3,clc);
          fcj = fcn(inm,2,jlc);
          scgbody{irow2,11} = sprintf('%.0f', fci);
          scgbody{irow2,12} = sprintf('%.0f', fcc);
          scgbody{irow2,13} = sprintf('%.0f', fcj);
        end

        %---
        if any(stn(inm,[1 7],1)~=0)
          irow1 = irow1+1;
          scgbody{irow1,4} = 'N';
          scgbody{irow1,5} = sprintf('%.0f', dfn(inm,1,ilc)*1.d-3);
          scgbody{irow1,9} = sprintf('%.0f', -dfn(inm,7,jlc)*1.d-3);
        end

        %---
        irow1 = irow1+1;
        scgbody{irow1,4} = 'M';
        scgbody{irow1,5} = sprintf('%.0f', -dfn(inm,5,ilc)*1.d-6);
        scgbody{irow1,7} = sprintf('%.0f', -Mc(imc,clc)*1.d-6);
        scgbody{irow1,9} = sprintf('%.0f', dfn(inm,11,jlc)*1.d-6);

        %---
        irow2 = irow2+1;
        scgbody{irow2,10} = 'Z';
        scgbody{irow2,11} = sprintf('%.0f', Zij(im1)*1.d-3);
        scgbody{irow2,12} = sprintf('%.0f', Zc(imc)*1.d-3);
        scgbody{irow2,13} = sprintf('%.0f', Zij(im2)*1.d-3);

        %---
        irow1 = irow1+1;
        scgbody{irow1,4} = 'Q';
        scgbody{irow1,5} = sprintf('%.0f', dfn(inm,3,ilc)*1.d-3);
        scgbody{irow1,9} = sprintf('%.0f', dfn(inm,9,jlc)*1.d-3);

        %---
        if any(stn(inm,[1 7],1)~=0)
          irow2 = irow2+1;
          scgbody{irow2,10} = 'A';
          % scgbody{irow2,11} = sprintf('%.0f', A(im1)*1.d-2);
          scgbody{irow2,12} = sprintf('%.0f', A(imc)*1.d-2);
          % scgbody{irow2,13} = sprintf('%.0f', A(im2)*1.d-2);
        end

        %---
        irow2 = irow2+1;
        scgbody{irow2,10} = 'Aw';
        scgbody{irow2,11} = sprintf('%.0f', Aw(im1)*1.d-2);
        scgbody{irow2,13} = sprintf('%.0f', Aw(im2)*1.d-2);

        %---
        if any(stn(inm,[1 7],1)~=0)
          irow2 = irow2+1;
          scgbody{irow2,10} = 'σb';
          scgbody{irow2,11} = sprintf('%.0f', -stn(inm,5,ilc));
          scgbody{irow2,12} = sprintf('%.0f', stcn(inm,clc));
          scgbody{irow2,13} = sprintf('%.0f', stn(inm,11,jlc));
          irow2 = irow2+1;
          scgbody{irow2,10} = 'σc';
          scgbody{irow2,11} = sprintf('%.0f', stn(inm,1,ilc));
          scgbody{irow2,13} = sprintf('%.0f', stn(inm,7,jlc));
        else
          irow2 = irow2+1;
          scgbody{irow2,10} = 'σ';
          scgbody{irow2,11} = sprintf('%.0f', -stn(inm,5,ilc));
          scgbody{irow2,12} = sprintf('%.0f', stcn(inm,clc));
          scgbody{irow2,13} = sprintf('%.0f', stn(inm,11,jlc));
        end

        %---
        irow2 = irow2+1;
        scgbody{irow2,10} = 'τ';
        scgbody{irow2,11} = sprintf('%.0f', stn(inm,3,ilc));
        scgbody{irow2,13} = sprintf('%.0f', stn(inm,9,jlc));

        %---
        if any(stn(inm,[1 7],1)~=0)
          irow2 = irow2+1;
          scgbody{irow2,10} = 'σb/fb';
          scgbody{irow2,11} = sprintf('%.2f', ration(inm,5,ilc));
          % scgbody{irow2,12} = sprintf('%.2f', ratio(inm,13,clc));
          scgbody{irow2,13} = sprintf('%.2f', ration(inm,11,jlc));
          %---
          irow2 = irow2+1;
          scgbody{irow2,10} = 'σc/fc';
          scgbody{irow2,11} = sprintf('%.2f', ration(inm,1,ilc));
          % scgbody{irow2,12} = sprintf('%.2f', grc(ig,clc));
          scgbody{irow2,13} = sprintf('%.2f', ration(inm,7,jlc));
          %---
          irow2 = irow2+1;
          scgbody{irow2,10} = 'TOTAL';
          scgbody{irow2,11} = sprintf('%.2f', gri(ing,ilc));
          scgbody{irow2,12} = sprintf('%.2f', grc(ing,clc));
          scgbody{irow2,13} = sprintf('%.2f', grj(ing,jlc));
        else
          irow2 = irow2+1;
          scgbody{irow2,10} = 'σ/fb';
          scgbody{irow2,11} = sprintf('%.2f', gri(ing,ilc));
          scgbody{irow2,12} = sprintf('%.2f', grc(ing,clc));
          scgbody{irow2,13} = sprintf('%.2f', grj(ing,jlc));
        end

        %---
        % irow1 = irow1+1;
        % scgbody{irow1,8} = sprintf('λ %.0f', lambda(im1,1));

        %---
        irow2 = irow2+1;
        scgbody{irow2,10} = 'τ/fs';
        scgbody{irow2,11} = sprintf('%.2f', gsi(ing,ilc));
        scgbody{irow2,13} = sprintf('%.2f', gsj(ing,jlc));

        %---
        % irow1 = irow1+1;
        % scgbody{irow1,1} = 'たわみ δ';
        % scgbody{irow1,2} = sprintf('%.3f', dangle(ig)*lm(im));
        % scgbody{irow1,3} = 'δ/L';
        % scgbody{irow1,4} = sprintf('1/%.0f', 1/dangle(ig));

        % 整理
        irow1 = max(irow1,irow2);
        irow2 = irow1;
      end
    end
  end
end
scgbody = scgbody(1:irow1,:);
return
end

        % scgbody((irow-1)*mb+1,:) = {...
        %   '', '', '', '', '左端', 'JOINT', ...
        %   '中央', 'JOINT', '右端', '', '左端', '中央', '右端'};
        % isg = girder.idsecg(ig);
        % im = girder.idme(ig);
        % [grimax, ilc] = max(gri(ig,:));
        % [grcmax, clc] = max(grc(ig,:));
        % [grjmax, jlc] = max(grj(ig,:));
        % 
        % %--
        % scgbody{(irow-1)*mb+1,1} = sprintf('[%s]', ...
        %   [secg.subindex{isg} secg.name{isg}]);
        % scgbody{(irow-1)*mb+2,1} = girder.story_name{ig};
        % scgbody{(irow-1)*mb+2,2} = girder.frame_name{ig};
        % scgbody{(irow-1)*mb+2,3} = sprintf('%s-%s', ...
        %   girder.coord_name{ig,1}, girder.coord_name{ig,2});
        % scgbody{(irow-1)*mb+2,4} = '位置';
        % scgbody{(irow-1)*mb+2,5} = sprintf('%.0f',lfg(ig,1));
        % scgbody{(irow-1)*mb+2,7} = lm(im)/2;
        % scgbody{(irow-1)*mb+2,9} = sprintf('%.0f',lfg(ig,2));
        % scgbody{(irow-1)*mb+2,10} = 'ケース';
        % scgbody{(irow-1)*mb+2,11} = PRM.load_case_name(ilc);
        % scgbody{(irow-1)*mb+2,12} = PRM.load_case_name(clc);
        % scgbody{(irow-1)*mb+2,13} = PRM.load_case_name(jlc);
        % 
        % %---
        % scgbody{(irow-1)*mb+3,4} = 'ML''';
        % scgbody{(irow-1)*mb+3,5} = sprintf('%.0f', -rs(im,5,1)*1.d-6);
        % scgbody{(irow-1)*mb+3,7} = sprintf('%.0f', -Mc(im,1)*1.d-6);
        % scgbody{(irow-1)*mb+3,9} = sprintf('%.0f', rs(im,11,1)*1.d-6);
        % scgbody{(irow-1)*mb+3,10} = 'Lb';
        % scgbody{(irow-1)*mb+3,11} = Lb(ig,1);
        % scgbody{(irow-1)*mb+3,12} = Lb(ig,3);
        % scgbody{(irow-1)*mb+3,13} = Lb(ig,2);
        % 
        % %---
        % scgbody{(irow-1)*mb+4,4} = 'QL';
        % scgbody{(irow-1)*mb+4,5} = sprintf('%.0f', rs(im,3,1)*1.d-3);
        % scgbody{(irow-1)*mb+4,9} = sprintf('%.0f', rs(im,9,1)*1.d-3);
        % scgbody{(irow-1)*mb+4,10} = 'C';
        % scgbody{(irow-1)*mb+4,11} = sprintf('%.2f', C(ig,1,ilc));
        % scgbody{(irow-1)*mb+4,12} = sprintf('%.2f', C(ig,2,clc));
        % scgbody{(irow-1)*mb+4,13} = sprintf('%.2f', C(ig,3,jlc));
        % %---
        % scgbody{(irow-1)*mb+5,4} = '[部材]';
        % scgbody{(irow-1)*mb+5,10} = 'fb';
        % scgbody{(irow-1)*mb+5,11} = sprintf('%.0f', fb(ig,1,ilc));
        % scgbody{(irow-1)*mb+5,12} = sprintf('%.0f', fb(ig,2,clc));
        % scgbody{(irow-1)*mb+5,13} = sprintf('%.0f', fb(ig,3,jlc));
        % 
        % %---
        % scgbody{(irow-1)*mb+6,4} = 'M';
        % scgbody{(irow-1)*mb+6,5} = sprintf('%.0f', -rs(im,5,ilc)*1.d-6);
        % scgbody{(irow-1)*mb+6,7} = sprintf('%.0f', -Mc(im,clc)*1.d-6);
        % scgbody{(irow-1)*mb+6,9} = sprintf('%.0f', rs(im,11,jlc)*1.d-6);
        % scgbody{(irow-1)*mb+6,10} = 'Z';
        % scgbody{(irow-1)*mb+6,11} = sprintf('%.0f', Zf(im)*1.d-3);
        % scgbody{(irow-1)*mb+6,12} = sprintf('%.0f', Zc(im)*1.d-3);
        % scgbody{(irow-1)*mb+6,13} = sprintf('%.0f', Zf(im)*1.d-3);
        % 
        % %---
        % scgbody{(irow-1)*mb+7,4} = 'Q';
        % scgbody{(irow-1)*mb+7,5} = sprintf('%.0f', rs(im,3,ilc)*1.d-3);
        % scgbody{(irow-1)*mb+7,9} = sprintf('%.0f', rs(im,9,jlc)*1.d-3);
        % scgbody{(irow-1)*mb+7,10} = 'Aw';
        % scgbody{(irow-1)*mb+7,11} = sprintf('%.0f', Aw(im)*1.d-2);
        % scgbody{(irow-1)*mb+7,13} = sprintf('%.0f', Aw(im)*1.d-2);
        % 
        % %---
        % scgbody{(irow-1)*mb+8,10} = 'σ';
        % scgbody{(irow-1)*mb+8,11} = sprintf('%.0f', -st(im,5,ilc));
        % scgbody{(irow-1)*mb+8,12} = sprintf('%.0f', stc(im,clc));
        % scgbody{(irow-1)*mb+8,13} = sprintf('%.0f', st(im,11,jlc));
        % 
        % %---
        % scgbody{(irow-1)*mb+9,10} = 'τ';
        % scgbody{(irow-1)*mb+9,11} = sprintf('%.0f', st(im,3,ilc));
        % scgbody{(irow-1)*mb+9,13} = sprintf('%.0f', st(im,9,jlc));
        % 
        % %---
        % scgbody{(irow-1)*mb+10,10} = 'σ/fb';
        % scgbody{(irow-1)*mb+10,11} = sprintf('%.2f', gri(ig,ilc));
        % scgbody{(irow-1)*mb+10,12} = sprintf('%.2f', grc(ig,clc));
        % scgbody{(irow-1)*mb+10,13} = sprintf('%.2f', grj(ig,jlc));
        % 
        % %---
        % scgbody{(irow-1)*mb+11,8} = sprintf('λ %.0f', lambda(im));
        % scgbody{(irow-1)*mb+11,10} = 'τ/fs';
        % scgbody{(irow-1)*mb+11,11} = sprintf('%.2f', gsi(ig,ilc));
        % scgbody{(irow-1)*mb+11,13} = sprintf('%.2f', gsj(ig,jlc));
        % 
        % %---
        % scgbody{(irow-1)*mb+12,1} = 'たわみ δ';
        % scgbody{(irow-1)*mb+12,2} = sprintf('%.3f', dangle(ig)*lm(im));
        % scgbody{(irow-1)*mb+12,3} = 'δ/L';
        % scgbody{(irow-1)*mb+12,4} = sprintf('1/%.0f', 1/dangle(ig));
