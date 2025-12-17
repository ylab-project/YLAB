function [dgflhead, dgflbody] = ...
  write_cell_design_girder_force_list(com, result, icase)
%writeSectionProperties - Write section properties

% 定数
ng = com.nmeg;
nng = com.num.nominal_girder;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
nominal_girder = com.nominal.girder;
girder = com.member.girder;
secg = com.section.girder;
lm_nominal = result.lm_nominal;
dfn_all = result.dfn;
Mc_all = result.Mc;

% ID変換
idnmg2x = girder.idx(nominal_girder.idmeg(:,1),1);
idnmg2y = girder.idy(nominal_girder.idmeg(:,1),1);
% idnmg2z = girder.idz(nominal_girder.idmeg(:,1),1);
idnmg2story = girder.idstory(nominal_girder.idmeg(:,1),1);
idnmg2mg = nominal_girder.idmeg;
idnmg2nm = nominal_girder.idnominal;
idnmg2dir = nominal_girder.idir;
idmg2m = girder.idme;

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

% --- 変位量（重心位置） ---
dgflhead = { ...
  '層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', 'ケース', ...
  '部材長', '左端M', '中央M', '右端M', '左端Q', '中央Q', '右端Q'; ...
  '', '', '', '', '', '', ...
  'mm', 'kNm', 'kNm', 'kNm', 'kN', 'kN', 'kN'};
dgncol = size(dgflhead,2);
dgflbody = cell(0,dgncol);
if nng==0 || isempty(lm_nominal)
  return
end
if isempty(dfn_all) || size(dfn_all,3)<maxlc
  return
end
if isempty(Mc_all) || size(Mc_all,2)<maxlc
  return
end
dfn = dfn_all(:,:,ilcset);
Mc = Mc_all(:,ilcset);
isprintN = any(dfn~=0,'all');
if isprintN
  dgflhead(1,14:16) = {'左端N', '中央N', '右端N'};
  dgflhead(2,14:16) = {'kN', 'kN', 'kN'};
end
dgncol = size(dgflhead,2);

% --- 表書き出し ---
rows = cell(ng*nlc,dgncol);
iggg = 1:nng;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  idir = 1;
  for iy = 1:nbly
    for ix = 1:nblx
      print_body;
    end
  end
  idir = 2;
  for ix = 1:nblx
    for iy = 1:nbly
      print_body;
      % ig = iggg(girder.idstory==ist & girder.idx(:,1)==ix & ...
      %   girder.idy(:,1)==iy & girder.idir==idir);
      % if isempty(ig)
      %   continue
      % end
      % irow = irow+1;
      % dgflbody{(irow-1)*nlc+1,1} = girder.story_name{ig};
      % dgflbody{(irow-1)*nlc+1,2} = girder.frame_name{ig};
      % dgflbody{(irow-1)*nlc+1,3} = girder.coord_name{ig,1};
      % dgflbody{(irow-1)*nlc+1,4} = girder.coord_name{ig,2};
      % isg = girder.idsecg(ig);
      % dgflbody{(irow-1)*nlc+1,5} = [secg.subindex{isg} secg.name{isg}];
      % im = girder.idme(ig);
      % dgflbody{(irow-1)*nlc+1,7} = lm(im);
      % for ilc=1:nlc
      %   dgflbody{(irow-1)*nlc+ilc,6} = label{ilc};
      %   dgflbody{(irow-1)*nlc+ilc,8} = sprintf('%.0f', -df(im,5,ilc)*1.d-6);
      %   dgflbody{(irow-1)*nlc+ilc,9} = sprintf('%.0f', -Mc(ig,ilc)*1.d-6);
      %   dgflbody{(irow-1)*nlc+ilc,10} = sprintf('%.0f', df(im,11,ilc)*1.d-6);
      %   dgflbody{(irow-1)*nlc+ilc,11} = sprintf('%.0f', df(im,3,ilc)*1.d-3);
      %   dgflbody{(irow-1)*nlc+ilc,12} = '';
      %   dgflbody{(irow-1)*nlc+ilc,13} = sprintf('%.0f', df(im,9,ilc)*1.d-3);
      %   if isprintN
      %     dgflbody{(irow-1)*nlc+ilc,14} = sprintf('%.0f', df(im,1,ilc)*1.d-3);
      %     dgflbody{(irow-1)*nlc+ilc,16} = sprintf('%.0f', -df(im,7,ilc)*1.d-3);
      %   end
      % end
    end
  end
end
if irow==0
  dgflbody = cell(0,dgncol);
else
  dgflbody = rows(1:irow,:);
end
return
%------------------------------------------------------------------------
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
      rows{irow,6} = label{ilc};
      rows{irow,8} = sprintf('%.0f', -dfn(inm,5,ilc)*1.d-6);
      rows{irow,9} = sprintf('%.0f', -Mc(ig1,ilc)*1.d-6);
      rows{irow,10} = sprintf('%.0f', dfn(inm,11,ilc)*1.d-6);
      rows{irow,11} = sprintf('%.0f', dfn(inm,3,ilc)*1.d-3);
      rows{irow,12} = '';
      rows{irow,13} = sprintf('%.0f', dfn(inm,9,ilc)*1.d-3);
      if isprintN
        rows{irow,14} = sprintf('%.0f', dfn(inm,1,ilc)*1.d-3);
        rows{irow,16} = sprintf('%.0f', -dfn(inm,7,ilc)*1.d-3);
      end
    end
  end
end
