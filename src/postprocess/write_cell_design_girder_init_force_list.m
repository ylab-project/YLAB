function [dgiflhead, dgiflbody] = ...
  write_cell_design_girder_init_force_list(com, result)
%writeSectionProperties - Write section properties

% 定数
ng = com.nmeg;
nng = com.num.nominal_girder;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;
dfn0_all = result.dfn0;
nlc = size(dfn0_all,3);

% 共通配列
nominal_girder = com.nominal.girder;
girder = com.member.girder;
secg = com.section.girder;
lm_nominal = result.lm_nominal;

% ID変換
idnmg2x = girder.idx(nominal_girder.idmeg(:,1),1);
idnmg2y = girder.idy(nominal_girder.idmeg(:,1),1);
% idnmg2z = girder.idz(nominal_girder.idmeg(:,1),1);
idnmg2story = girder.idstory(nominal_girder.idmeg(:,1),1);
idnmg2mg = nominal_girder.idmeg;
idnmg2nm = nominal_girder.idnominal;
idnmg2dir = nominal_girder.idir;
idmg2m = girder.idme;

% --- 柱設計応力表 ---
dgiflhead = cell(3,12);
dgiflhead(1,1:11) = { ...
  '層','ﾌﾚｰﾑ','軸－軸','','符号', ...
  'ケース','部材長','曲げ','','', ...
  'せん断'};

dgiflhead(2,6:12) = { ...
  '','','左端','中央','右端', ...
  '左端','右端'};

dgiflhead(3,6:12) = { ...
  '','mm','kNm','kNm','kNm', ...
  'kN','kN'};

ncol = size(dgiflhead,2);
dgiflbody = cell(0,ncol);
if nng==0 || isempty(lm_nominal)
  return
end
if isempty(dfn0_all) || nlc==0
  return
end
dfn0 = dfn0_all;
rows = cell(ng*nlc,ncol);
iggg = 1:nng;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  idir = 1;
  for iy = 1:nbly
    for ix = 1:nblx
      print_body
    end
  end
  idir = 2;
  for ix = 1:nblx
    for iy = 1:nbly
      print_body
    end
  end
end
if irow==0
  dgiflbody = cell(0,ncol);
else
  dgiflbody = rows(1:irow,:);
end
%--------------------------------------------------------------------------
  function print_body
    % --- 該当ID検索 ---
    ing = iggg(idnmg2story==ist ...
      & idnmg2x(:,1)==ix & idnmg2y(:,1)==iy & idnmg2dir(:)==idir);
    if isempty(ing)
      return
    end

    % --- 箇所ごとの部材番号 ---
    inm = idnmg2nm(ing);
    idsub = nominal_girder.idsub(ing,:);
    ig1 = idnmg2mg(ing,idsub(1)); im1 = idmg2m(ig1);
    ig2 = idnmg2mg(ing,idsub(2)); im2 = idmg2m(ig2);

    for ilc=1:nlc
      irow = irow+1;
      if ilc==1
        rows{irow,1} = girder.story_name{ig1};
        rows{irow,2} = girder.frame_name{ig1};
        rows{irow,3} = girder.coord_name{ig1,1};
        rows{irow,4} = girder.coord_name{ig2,2};
        isg = girder.idsecg(ig1);
        rows{irow,5} = [secg.subindex{isg} secg.name{isg}];
        rows{irow,7} = sprintf('%.0f', lm_nominal(im1));
      end
      rows{irow,6} = PRM.load_case_name(ilc);
      rows{irow,8} = sprintf('%.2f', -dfn0(inm,5,ilc)*1.d-6);
      % rows{irow,9} = sprintf('%.2f', -Mc(ig1,ilc)*1.d-6);
      rows{irow,10} = sprintf('%.2f', dfn0(inm,11,ilc)*1.d-6);
      rows{irow,11} = sprintf('%.2f', dfn0(inm,3,ilc)*1.d-3);
      rows{irow,12} = sprintf('%.2f', dfn0(inm,9,ilc)*1.d-3);
      % if isprintN
      %   rows{(irow-1)*nlc+ilc,14} = sprintf('%.0f', rs(im,1,ilc)*1.d-3);
      %   rows{(irow-1)*nlc+ilc,16} = sprintf('%.0f', -rs(im,7,ilc)*1.d-3);
      % end
    end
    return
  end
end
