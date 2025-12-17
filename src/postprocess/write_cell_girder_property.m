function [gphead, gpbody] = ...
  write_cell_girder_property(com, result)
%write_cell_girder_property 梁断面を出力するセル配列を生成

% 定数
ng = com.nmeg;
nstory = com.nstory;

% 共通配列
girder = com.member.girder;
secg = com.section.girder;
msprop = result.msprop;
Iy = result.Iy;
gphiI = result.gphiI;
lm = result.lm;
lfg = result.lf.girder;
lrg = result.lr.girder;

% 準備計算
Em = msprop.E;
Gm = msprop.E./(2*(1+msprop.pr));

% --- 梁断面 ---
gphead = {...
  '層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', 'E', ...
  'Io',	'φI', 'I', 'Aso', 'φQ', 'As', ...
  'α', 'β', '部材長', '剛域', 'ﾌｪｲｽ' ...
  'ﾊﾟﾈﾙ', '結合'; ...
  '', '', '', '', '', 'G', ...
  '', '', '', 'Ano', 'φn', 'An', ...
  'αn', 'κ', '', '左/右', '左/右' ...
  '左/右', '左/右';
  '', '', '', '', '', 'kN/mm2', ...
  'cm4', '', 'cm4', 'cm2', '', 'cm2', ...
  '', '', 'mm',	'mm', 'mm' ...
  'mm', ''};
gpbody = cell(ng*2,17);
irow = 0;
for i=1:nstory
  ist = nstory-i+1;
  for ig = 1:ng
    if girder.idstory(ig)~=ist
      continue
    end
    gtype = girder.type(ig);
    if gtype == PRM.GIRDER_FOR_KBRACE2
      continue
    end
    if gtype == PRM.GIRDER_FOR_KBRACE1
      ig_pair = girder.idconnected_girder(ig);
    else
      ig_pair = 0;
    end
    irow = irow+1;
    write_gp_entry(ig, ig_pair);
  end
end

return

  function write_gp_entry(ig_left, ig_right)
    if ig_right <= 0
      ig_right = ig_left;
    end
    write_gp_left(irow, ig_left);
    write_gp_right(irow, ig_right);
  end

  function write_gp_left(irow_, ig_)
    idm_ = girder.idme(ig_);
    gpbody{irow_*2-1,1} = girder.story_name{ig_};
    gpbody{irow_*2-1,2} = girder.frame_name{ig_};
    gpbody{irow_*2-1,3} = girder.coord_name{ig_,1};
    gpbody{irow_*2-1,4} = '';
    idsec_ = girder.idsecg(ig_);
    sub = secg.subindex{idsec_};
    if strcmp(sub, '-')
        gpbody{irow_*2-1,5} = secg.name{idsec_};
    else
        gpbody{irow_*2-1,5} = [sub secg.name{idsec_}];
    end
    gpbody{irow_*2-1,6} = Em(idm_)*1.d-3;
    gpbody{irow_*2-1,7} = sprintf('%.0f', msprop.Iy(idm_)*1.d-4);
    gpbody{irow_*2-1,8} = sprintf('%.3f', gphiI(ig_));
    gpbody{irow_*2-1,9} = sprintf('%.0f', Iy(idm_)*1.d-4);
    gpbody{irow_*2-1,10} = sprintf('%.2f', msprop.Asy(idm_)*1.d-2);
    gpbody{irow_*2-1,11} = 1;
    gpbody{irow_*2-1,12} = sprintf('%.2f', msprop.Asy(idm_)*1.d-2);
    gpbody{irow_*2-1,13} = 1;
    gpbody{irow_*2-1,14} = 1;
    gpbody{irow_*2-1,15} = sprintf('%.0f', lm(idm_));
    gpbody{irow_*2-1,16} = sprintf('%.0f', lrg(ig_,1));
    gpbody{irow_*2-1,17} = sprintf('%.0f', lfg(ig_,1));
    gpbody{irow_*2-1,19} = joint_label(girder.joint(ig_,1));
  end

  function write_gp_right(irow_, ig_)
    idm_ = girder.idme(ig_);
    gpbody{irow_*2-1,4} = girder.coord_name{ig_,2};
    gpbody{irow_*2,6} = sprintf('%.1f', Gm(idm_)*1.d-3);
    % gpbody{irow_*2,7} = sprintf('%.0f', msprop.Iy(idm_)*1.d-4);
    % gpbody{irow_*2,8} = sprintf('%.3f', gphiI(ig_));
    % gpbody{irow_*2,9} = sprintf('%.0f', Iy(idm_)*1.d-4);
    gpbody{irow_*2,10} = sprintf('%.1f', msprop.A(idm_)*1.d-2);
    gpbody{irow_*2,11} = 1;
    gpbody{irow_*2,12} = sprintf('%.1f', msprop.A(idm_)*1.d-2);
    gpbody{irow_*2,13} = 1;
    gpbody{irow_*2,14} = 1;
    % gpbody{irow_*2,15} = sprintf('%.0f', lm(idm_));
    gpbody{irow_*2,16} = sprintf('%.0f', lrg(ig_,2));
    gpbody{irow_*2,17} = sprintf('%.0f', lfg(ig_,2));
    gpbody{irow_*2,19} = joint_label(girder.joint(ig_,2));
  end

  function label = joint_label(value)
    switch value
      case PRM.PIN
        label = "ピン";
      case PRM.FIX
        label = "剛接";
      otherwise
        label = "";
    end
  end
end
