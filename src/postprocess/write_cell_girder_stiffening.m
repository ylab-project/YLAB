function stgcell = write_cell_girder_stiffening(com, result)
%writeSectionProperties - Write section properties

% 定数
ng = com.nmeg;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
girder = com.member.girder;
secg = com.section.girder;
slratio = result.slratio;
gstype = girder.section_type;
% lm = com.member.property.lm;
conslr = result.conslr;

% --- ヘッダー ---
head = cell(4,1);
head(1,1:19) = { ...
  '層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', ...
  '部材長', 'n', '左端', '', '右端', ...
  '', '最大Lb', '等間隔に設ける', '', '', ...
  '端部に設ける', '', '', '判定';};
head(2,8:18) = {'Lb1','Lb2', 'Lb2', 'Lb1', '(入力)', ...
  'λ', '限界Lb', '必要n', 'Myを超える範囲', '', '限界Lb'};
head(4,8:18) = {'mm', 'mm', 'mm', 'mm', 'mm', ...
  '', 'mm', '', 'mm', 'mm', 'mm'};

% --- 保有耐力横補剛 ---
body = cell(ng,16);
if isempty(slratio)
  stgcell.head = head;
  stgcell.body = body;
  return
end
iggg = 1:ng;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  idir = 1;
  for iy = 1:nbly
    for ix = 1:nblx
      ig = iggg(girder.idstory==ist & girder.idx(:,1)==ix & ...
        girder.idy(:,1)==iy & girder.idir==idir);
      if isempty(ig) || gstype(ig) ~=PRM.WFS
        continue
      end
      if all(girder.joint(ig,1:2)==PRM.PIN)
        continue
      end
      irow = irow+1;
      print_row
    end
  end
  idir = 2;
  for ix = 1:nblx
    for iy = 1:nbly
      ig = iggg(girder.idstory==ist & girder.idx(:,1)==ix & ...
        girder.idy(:,1)==iy & girder.idir==idir);
      if isempty(ig) || gstype(ig) ~=PRM.WFS
        continue
      end
      if all(girder.joint(ig,1:2)==PRM.PIN)
        continue
      end
      irow = irow+1;
      print_row
    end
  end
end
% head(:,8:11) = [];
% body(:,8:11) = [];
stgcell.head = head;
stgcell.body = body;
return
  function print_row
    body{irow,1} = girder.story_name{ig};
    body{irow,2} = girder.frame_name{ig};
    body{irow,3} = girder.coord_name{ig,1};
    body{irow,4} = girder.coord_name{ig,2};
    isg = girder.idsecg(ig);
    body{irow,5} = [secg.subindex{isg} secg.name{isg}];
    body{irow,6} = sprintf('%.0f', slratio.lg(ig));
    % body{irow,7} = sprintf('%.1f', slratio.n(ig));
    if slratio.lb(ig,1)~=slratio.lg(ig)
      body{irow,8} = sprintf('%.0f', slratio.lb(ig,1));
    end
    if slratio.lb(ig,2)~=slratio.lg(ig)
      body{irow,11} = sprintf('%.0f', slratio.lb(ig,2));
    end
    body{irow,12} = sprintf('%.0f', slratio.lb(ig,3));
    % body{irow,12} = slratio.lb(ig);
    % if (slratio.n(ig)>0)
    body{irow,13} = sprintf('%.0f', slratio.lambda(ig));
    body{irow,14} = sprintf('%.0f', slratio.lbreq1(ig));
    % body{irow,14} = sprintf('%.0f', slratio.iyreq(ig));
    % end
    body{irow,15} = slratio.nreq(ig);
    body{irow,16} = sprintf('%.0f', slratio.lbmy(ig,1));
    body{irow,17} = sprintf('%.0f', slratio.lbmy(ig,2));
    body{irow,18} = sprintf('%.0f', slratio.lbreq2(ig));
    if conslr(ig)<=0
      judgement = 'OK';
    else
      judgement = 'NG';
    end
    body{irow,19} = judgement;
  end

end
