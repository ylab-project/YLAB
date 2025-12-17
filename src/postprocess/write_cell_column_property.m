function [cphead, cpbody] = write_cell_column_property(com, result)
%writeSectionProperties - Write section properties

% 定数
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nc = com.nmec;
% ng = com.nmeg;
nb = com.nmeb;
% nm = com.nme;
% nstory = com.nstory;
nfl = com.nfl;
idmc2m = com.member.column.idme;
idm2scb = com.member.property.idseccb;
% idm2s = com.member.property.idsec;
% ids2mat = result.ids2mat;

% 共通配列
column = com.member.column;
% girder = com.member.girder;
% brace = com.member.brace;
secc = com.section.column;
% secg = com.section.girder;
% secb = com.section.brace;
% story = com.story;
floor = com.floor;
% matE = com.material.E;
% matG = com.material.E./(2*(1+com.material.pr));
msprop = result.msprop;
Iy = result.Iy;
Iz = result.Iz;
cphiI = result.cphiI;
% gphiI = result.gphiI;
lm = result.lm;
% lfg = result.lf.girder;
lfcx = result.lf.columnx;
lfcy = result.lf.columny;
% lrg = result.lr.girder;
lrcx = result.lr.columnx;
lrcy = result.lr.columny;
cbstiff = result.cbs.stiff;
nominal_column = com.nominal.column;

% 準備計算
% idm2mat = ids2mat(idm2s);
% idnm2mc = nominal_column.idmec;
idmc2nmc = column.idnominal;
Em = msprop.E;
Gm = msprop.E./(2*(1+msprop.pr));

% --- 柱断面 ---
cphead = cell(3,27);
cphead(1,:) = { ...
  '階', 'X軸', 'Y軸', '符号', '方', 'E', 'G', ...
  'Io', 'φI', 'I', 'Aso', 'Ano', ...
  'φQ', 'φn', 'As', 'An', 'α', 'αn', ...
  'β', 'κ', '部材長', '剛域', '', 'フェイス位置', '', '結合状態', ''};
cphead(2,:) = { ...
  '', '', '', '', '向', '', ...
  '', '', '', '', '', '', ...
  '', '', '', '', '', '', ...
  '', '', '', '柱頭', '柱脚', '柱頭', '柱脚', '柱頭', '柱脚'};
cphead(3,:) = { ...
  '', '', '', '', '', 'kN/mm2', ...
  'kN/mm2', '', 'cm4', 'cm4', 'cm2', 'cm2' ...
  '', '', 'cm2', 'cm2', '', '', ...
  '', '', 'mm', 'mm', 'mm', 'mm', 'mm', 'kNm/rad', 'kNm/rad'};

cpbody = cell(nc*2,27);
irow = 0;
iccc = 1:nc;
for i=1:nfl
  ifl = nfl-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        % 柱脚側で判定する（SS7ルール）
        % ic = iccc(column.idstory==ist & ...
        %   column.idx(:,1)==ix & column.idy(:,1)==iy & column.idz(:,1)==iz);
        ic = iccc(column.idfloor==ifl & ...
          column.idx(:,1)==ix & column.idy(:,1)==iy & column.idz(:,1)==iz);
        if isempty(ic)
          continue
        end
        if column.type(ic) == PRM.COLUMN_FOR_BRACE2
          continue
        end
        % 共通
        idm = column.idme(ic);
        lm_ = lm(idm);
        lfcx_ = lfcx(ic,:);
        lfcy_ = lfcy(ic,:);
        iscb_ = idm2scb(idm);
        % 分割部材対応
        if column.type(ic) == PRM.COLUMN_FOR_BRACE1
          idnmc = idmc2nmc(ic);
          idcc = nominal_column.idmec(idnmc,:);
          idmm = idmc2m(idcc);
          lm_ = sum(lm(idmm));
          lfcx_(2) = lfcx(idcc(2),2);
          lfcy_(2) = lfcy(idcc(2),2);
          iscb_ = idm2scb(idmm(2));
        end
        % 剛性表
        write_cpbody
      end
    end
  end
end

% % ブレースがある場合
% if nb==0
%   return
% end
% % cphead = cphead(:,[1:8 9 9 9 10:end]);
% % % , cpbody

return
%--------------------------------------------------------------------------
  function write_cpbody
    irow = irow+1;
    % floor_name = story.floor_name{ist};
    floor_name = floor.name{ifl};
    cpbody{irow*2-1,1} = floor_name;
    cpbody(irow*2-1,2:3) = column.coord_name(ic,1:2);
    idsc = column.idsecc(ic);
    sub = secc.subindex{idsc};
    if strcmp(sub, '-')
        cpbody{irow*2-1,4} = secc.name{idsc};
    else
        cpbody{irow*2-1,4} = [sub secc.name{idsc}];
    end
    cpbody(irow*2-1:irow*2,5) = {'x'; 'y'};
    cpbody{irow*2-1,6} = Em(idm)*1.d-3;
    cpbody{irow*2-1,7} = sprintf('%.1f', Gm(idm)*1.d-3);
    cpbody{irow*2-1,8} = sprintf('%.0f', msprop.Iy(idm)*1.d-4);
    cpbody{irow*2,8} = sprintf('%.0f', msprop.Iz(idm)*1.d-4);
    cpbody{irow*2-1,9} = sprintf('%.3f', cphiI(ic,1));
    cpbody{irow*2,9} = sprintf('%.3f', cphiI(ic,2));
    cpbody{irow*2-1,10} = sprintf('%.0f', Iy(idm)*1.d-4);
    cpbody{irow*2,10} = sprintf('%.0f', Iz(idm)*1.d-4);
    As = sprintf('%.1f', msprop.Asy(idm)*1.d-2);
    An = sprintf('%.1f', msprop.A(idm)*1.d-2);
    cpbody(irow*2-1:irow*2,11) = {As; As};
    cpbody{irow*2-1,12} = An;
    cpbody{irow*2-1,13} = 1;
    cpbody{irow*2,13} = 1;
    cpbody{irow*2-1,14} = 1;
    cpbody(irow*2-1:irow*2,15) = {As; As};
    cpbody{irow*2-1,16} = An;
    cpbody(irow*2-1:irow*2,17) = {1; 1};
    cpbody{irow*2-1,18} = 1;
    cpbody(irow*2-1:irow*2,19) = {1; 1};
    cpbody(irow*2-1:irow*2,20) = {1; 1};
    cpbody{irow*2-1,21} = sprintf('%.0f', lm_);
    cpbody(irow*2-1:irow*2,22) = ...
      {sprintf('%.0f', lrcx(ic,2)); sprintf('%.0f', lrcy(ic,2))};
    cpbody(irow*2-1:irow*2,23) = ...
      {sprintf('%.0f', lrcx(ic,1)); sprintf('%.0f', lrcy(ic,1))};
    cpbody(irow*2-1:irow*2,24) = ...
      {sprintf('%.0f', lfcx_(2)); sprintf('%.0f', lfcy_(2))};
    cpbody(irow*2-1:irow*2,25) = ...
      {sprintf('%.0f', lfcx_(1)); sprintf('%.0f', lfcy_(1))};
    % cpbody(irow*2-1:irow*2,26:27) = {'剛接', '剛接'; '剛接', '剛接'};
    % column.joint(ic,:) 1:X柱脚, 2:X柱頭, 3:Y柱脚, 4:Y柱頭
    for jxy=1:2
      for kbt=1:2
        jjj = jxy*2+kbt-2;
        switch column.joint(ic,jjj)
          case PRM.PIN
            cpbody{irow*2+jxy-2,28-kbt} = "ピン";
          case PRM.FIX
            cpbody{irow*2+jxy-2,28-kbt} = "剛接";
            % otherwise
            %   cpbody{irow*2+jxy-2,25+kbt} = "??";
        end
      end
    end
    if iscb_>0
      kcb = cbstiff(iscb_);
      cpbody(irow*2-1:irow*2,27) = ...
        {sprintf('%.0f', kcb*1.d-6); sprintf('%.0f', kcb*1.d-6)};
    end
    return
  end
end
