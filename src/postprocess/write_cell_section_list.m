function [gshead, gsbody, cshead, csbody] = write_cell_section_list(...
  secdim, com, options)
%write_cell_section_list - 柱梁断面リストのセル配列を生成する
%
%   [gshead, gsbody, cshead, csbody] =
%     write_cell_section_list(secdim, com, options) は、断面寸法から
%   梁・柱の断面リスト表を生成する。secdim が空の場合は、寸法値の
%   代わりに設計変数名を表示する。
%
%   入力引数:
%     secdim  - 写像済み断面寸法 [nsec×7]。空なら変数名を表示
%     com     - 共通データ構造体
%     options - オプション構造体
%
%   出力引数:
%     gshead - 梁断面リストの見出し行
%     gsbody - 梁断面リストの本体
%     cshead - 柱断面リストの見出し行
%     csbody - 柱断面リストの本体

% 共通定数
nstory = com.nstory;

% 共通配列
secg = com.section.girder;
secc = com.section.column;
seclist = com.sectionList.list;
story = com.story;
ids2var = com.section.property.idvar;
vname = com.design.variable.name;
gstype = com.section.girder.type;
cstype = com.section.column.type;

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
ng = com.nsecg;
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
        if isempty(secdim)
          iv = ids2var(is,:);
          sdim = sprintf('%s, %s, %s, %s', vname{iv(1:4)});
        else
          idslist = secdim(is, PRM.MAPPED_SECDIM_SLIST);
          idsection = secdim(is, PRM.MAPPED_SECDIM_SECTION);
          secglist = seclist{idslist};
          symbol = secglist.symbol{idsection};
          if secdim(is,5)==0
            % sdim = sprintf('%s-%g×%g×%g×%g', ...
            %   secg.type_name{ig}, secdim(is,1:4));
            sdim = sprintf('%s-%gx%gx%gx%g', symbol, secdim(is,1:4));
          else
            sdim = sprintf('%s-%gx%gx%gx%gx%g', symbol, secdim(is,1:5));
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
nc = com.nsecc;
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
        if isempty(secdim)
          iv = ids2var(is,:);
          sdim = sprintf('%s, %s', vname{iv(1:2)});
        else
          idslist = secdim(is, PRM.MAPPED_SECDIM_SLIST);
          idsection = secdim(is, PRM.MAPPED_SECDIM_SECTION);
          secclist = seclist{idslist};
          symbol = secclist.symbol{idsection};
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

