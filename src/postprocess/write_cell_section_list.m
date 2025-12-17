function [gshead, gsbody, cshead, csbody] = write_cell_section_list(...
  xvar, com, options)

% 共通定数
nstory = com.nstory;

% 共通配列
secg = com.section.girder;
secc = com.section.column;
secmgr = com.secmgr;
seclist = com.sectionList.list;
story = com.story;
ids2var = com.section.property.idvar;
vname = com.design.variable.name;
gstype = com.section.girder.type;
cstype = com.section.column.type;

% 断面寸法の計算
if ~isempty(xvar)
  secdim = secmgr.findNearestSection(xvar, options);
end

if isempty(options.output_girder_list_label)
  [grname, iddd] = unique(secg.name,'stable');
else
  [grname, iddd] = find_section_girder(secg.name);
end
% 方向の整理
% sdir = com.member.property.idir(com.section.girder.idrepm);
% srepdir = sdir(iddd);
% grxname = grname(srepdir==PRM.X);
% gryname = grname(srepdir==PRM.Y);
% isx = ismember(grname, grxname);
% isy = ismember(grname, gryname);
% idx = 1:length(iddd); idx = idx(isx);
% idy = 1:length(iddd); idy = idy(isy);

% 梁断面リスト出力
ngr = length(iddd);
ng = size(secg,1);
gshead = cell(1, ngr+1); gshead{1,1} = '層';
gsbody = cell(nstory, ngr+1);
isemptyrow = true(1,nstory);
for igr = 1:ngr
  % 該当断面の判別
  istarget = false(1,ng);
  for ig=1:ng
    if matches(secg.name{ig},grname{igr})
      istarget(ig) = true;
    end
  end
  % 出力
  for ist = nstory:-1:1
    gsbody{nstory-ist+1,1} = story.name{ist};
    for ig=1:ng
      if gstype(ig)~=PRM.WFS
        continue
      end
      if secg.idstory(ig)==ist && istarget(ig)
        gshead{1,igr+1} = secg.name{ig};
        is = secg.idsec(ig);
        if isempty(xvar)
          iv = ids2var(is,:);
          sdim = sprintf('%s, %s, %s, %s', vname{iv(1:4)});
        else
          secglist = seclist{secg.id_section_list(ig)};
          symbol = secglist.symbol{...
            secglist.H==secdim(is,1) & secglist.B==secdim(is,2) ...
            & secglist.tw==secdim(is,3) & secglist.tf==secdim(is,4)};
          if secdim(is,5)==0
            % sdim = sprintf('%s-%g×%g×%g×%g', ...
            %   secg.type_name{ig}, secdim(is,1:4));
            sdim = sprintf('%s-%gx%gx%gx%g', ...
              symbol, secdim(is,1:4));
          else
            % sdim = sprintf('%s-%g×%g×%g×%g×%g', ...
            %   secg.type_name{ig}, secdim(is,1:5));
            sdim = sprintf('%s-%gx%gx%gx%gx%g', ...
              symbol, secdim(is,1:5));
          end
        end
        gsbody{nstory-ist+1,igr+1} = sdim;
        isemptyrow(nstory-ist+1) = false;
      end
    end
  end
end
gsbody(isemptyrow,:) = [];

% 柱断面リスト出力
if isempty(options.output_column_list_label)
  [crname, iddd] = unique(secc.name,'stable');
  else
  [crname, iddd] = find_section_column(secc.name);
end

ncr = length(iddd);
nc = size(secc,1);
cshead = cell(1, ncr+1); cshead{1,1} = '階';
csbody = cell(nstory, ncr+1);
isemptyrow = true(1,nstory);
for icr = 1:ncr
  % 該当断面の判別
  istarget = false(1,nc);
  for ic=1:nc
    if matches(secc.name{ic},crname{icr})
      istarget(ic) = true;
    end
  end
  % 出力
  for ist = nstory:-1:1
    csbody{nstory-ist+1,1} = story.floor_name{ist};
    for ic=1:nc
      if cstype(ic)~=PRM.HSS
        continue
      end
      if secc.idstory(ic)==ist && istarget(ic)
        cshead{1,icr+1} = secc.name{ic};
        is = secc.idsec(ic);
        if isempty(xvar)
          iv = ids2var(is,:);
          sdim = sprintf('%s, %s', vname{iv(1:2)});
        else
          secclist = seclist{secc.id_section_list(ic)};
          symbol = secclist.symbol{...
            secclist.D == secdim(is,1) & secclist.t == secdim(is,2)};
          % sdim = sprintf('%s-%g×%g', secc.type_name{ic}, secdim(is,1:2));
          sdim = sprintf('%s-%gx%gx%gx%g', symbol, secdim(is,[1 1 2 3]));
        end
        csbody{nstory-ist+1,icr+1} = sdim;
        isemptyrow(nstory-ist+1) = false;
      end
    end
  end
end
csbody(isemptyrow,:) = [];
return
  function [grname, idsecg] = find_section_girder(secgname)
    n_ = length(options.output_girder_list_label);
    idsecg = zeros(n_,1);
    iddd_ = 1:length(secgname);
    for i_ = 1:n_
      iis = matches(secgname, options.output_girder_list_label{i_});
      if any(iis)
        ii = iddd_(iis);
        idsecg(i_) = ii(1);
      end
    end
    grname = options.output_girder_list_label';
    return
  end
  function [crname, idsecc] = find_section_column(seccname)
    n_ = length(options.output_column_list_label);
    idsecc = zeros(n_,1);
    iddd_ = 1:length(seccname);
    for i_ = 1:n_
      iis = matches(seccname, options.output_column_list_label{i_});
      if any(iis)
        ii = iddd_(iis);
        idsecc(i_) = ii(1);
      end
    end
    crname = options.output_column_list_label';
    return
  end
end

