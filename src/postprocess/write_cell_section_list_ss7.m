function [gshead, gsbody, cshead, csbody, ...
  cbshead, cbsbody] = ...
  write_cell_section_list_ss7(xvar, com, result, options)

% 共通定数
nstory = com.nstory;
ncb = com.nseccb;
nb = com.nsecb;

% 共通配列
secg = com.section.girder;
secc = com.section.column;
secb = com.section.brace;
seclist = com.sectionList.list;
stype = com.section.property.type;
cstype = com.section.column.type;
secmgr = com.secmgr;
material = com.material;

% 断面寸法の計算
if ~isempty(xvar)
  secdim = secmgr.findNearestSection(xvar, options);
end

% 梁断面リスト出力
ng = length(secg.name);
if isempty(options.output_girder_list_label)
  [grname, iddd] = sort_section_girder(secg.name);
else
  [grname, iddd] = find_section_girder(secg.name);
end
ngr = length(iddd);

% 出力準備
gshead = { ...
  '層', '梁符号', '添字', 'ハンチ', '', '鉄骨形状', ...
  '鉄骨登録形状', '', '', '', '', ''; ...
  '', '', '', '左端', '右端', '', ...
  '左端', 'タイプ左', '中央', 'タイプ中', '右端', 'タイプ右'};
gsbody = cell(ngr*nstory,12);
isemptyrow = true(1,nstory);

% 出力
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for igr = 1:ngr
    % 出力
    for ig=1:ng
      if iddd(igr)==0
        continue
      end
      if secg.idstory(ig)~=ist || ~matches(secg.name{ig},grname{igr})
        continue
      end
      if secg.id_section_list(ig)==0
        continue
      end
      secglist = seclist{secg.id_section_list(ig)};
      illl = 1:size(secglist,1);
      irow = irow+1;
      gsbody{irow,1} = secg.story_name{ig};
      gsbody{irow,2} = secg.name{ig};
      gsbody{irow,3} = secg.subindex{ig};
      gsbody{irow,4} = 0;
      gsbody{irow,5} = 0;
      type_name = secg.type_name{ig};
      if type_name == 'H'
        type_name = 'Ｈ';
      end
      gsbody{irow,6} = type_name;
      is = secg.idsec(ig);
      il = illl(secglist.H==secdim(is,1) & secglist.B==secdim(is,2) ...
        & secglist.tw==secdim(is,3) & secglist.tf==secdim(is,4));
      symbol = secglist.symbol{il};
      if secdim(is,5)==0
        sdim = sprintf('%s-%gx%gx%gx%g', symbol, secdim(is,1:4));
      else
        sdim = sprintf('%s-%gx%gx%gx%gx%g', symbol, secdim(is,1:5));
      end
      gsbody{irow,7} = sdim;
      gsbody{irow,8} = secglist.type{il};
      gsbody{irow,9} = sdim;
      gsbody{irow,10} = secglist.type{il};
      gsbody{irow,11} = sdim;
      gsbody{irow,12} = secglist.type{il};
      isemptyrow(irow) = false;
    end
  end
end
gsbody(isemptyrow,:) = [];

% 柱断面リスト出力
nc = length(secc.name);
if isempty(options.output_column_list_label)
  % [crname, iddd] = sort_section(secc.name);
  [crname, iddd] = unique(secc.name,'stable');
else
  [crname, iddd] = find_section_column(secc.name);
end
ncr = length(iddd);
% ncr = length(iddd);
% nc = size(secc,1);
cshead = {...
  '階', '柱符号', '添字', '鉄骨形状', '鉄骨断面', '', ''; ...
  '', '', '', '', '登録形状', 'タイプX', '鉄骨材料'};
csbody = cell(ncr*nstory, 7);
isemptyrow = true(1,ncr*nstory);
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for icr = 1:ncr
    % 出力
    for ic=1:nc
      if cstype(ic)~=PRM.HSS
        continue
      end
      if secc.idstory(ic)~=ist || ~matches(secc.name{ic},crname{icr})
        continue
      end
      secclist = seclist{secc.id_section_list(ic)};
      illl = 1:size(secclist,1);
      irow = irow+1;
      csbody{irow,1} = secc.floor_name{ic};
      csbody{irow,2} = secc.name{ic};
      csbody{irow,3} = secc.subindex{ic};
      type_name = secc.type_name{ic};
      csbody{irow,4} = type_name;
      is = secc.idsec(ic);
      il = illl(secclist.D == secdim(is,1) & secclist.t == secdim(is,2));
      if ~isempty(il)
        symbol = secclist.symbol{il};
        sectype = secclist.type{il};
      else
        symbol = '';
        sectype = '';
      end
      sdim = sprintf('%s-%gx%gx%gx%g', symbol, secdim(is,[1 1 2 3]));
      csbody{irow,5} = sdim;
      csbody{irow,6} = sectype;
      % 鉄骨材料
      idslist = secdim(is,6);
      idsection = secdim(is,7);
      idmaterial = secmgr.secList.idmaterial{idslist}(idsection);
      material_name = material.name{idmaterial};
      csbody{irow,7} = material_name;
      isemptyrow(irow) = false;
    end
  end
end
csbody(isemptyrow,:) = [];

% メーカー製柱脚断面リスト出力
cbshead = cell(3,7);
cbsbody = cell(ncb,5);
cbshead(1,1:7)= {'階','柱符号','形式','型名', '基礎柱', '', '回転剛性'};
cbshead(2,5:7)= {'Dx', 'Dy', 'kbs'};
cbshead(3,5:7)= {'mm', 'mm', 'kN･m/rad'};
% 共通配列
column_base = com.section.column_base;
column_base_list = com.column_base_list;
cbstiff = result.cbs.stiff;
cbsid = result.cbs.id;
cbsDf = result.cbs.Df;
irow = 0;
for icb = 1:ncb
  irow = irow+1;
  switch column_base.type(icb)
    case PRM.CB_DIRECT
      % 剛性指定
    case PRM.CB_LIST
      % 柱脚リスト
      cbsbody{irow,1} = column_base.floor_name{icb};
      cbsbody{irow,2} = column_base.section_name{icb};
      type = column_base_list(column_base.idlist(icb)).type{cbsid(icb)};
      name = column_base_list(column_base.idlist(icb)).name{cbsid(icb)};
      cbsbody{irow,3} = type;
      cbsbody{irow,4} = name;
  end
  cbsbody{irow,5} = cbsDf(icb);
  cbsbody{irow,6} = cbsDf(icb);
  cbsbody{irow,7} = cbstiff(icb)*1.d-9;
end

% ブレース断面リストは呼び出し元から別関数で処理される
return
%--------------------------------------------------------------------------
  function [grname, idsecg] = find_section_girder(secname)
    n_ = length(options.output_girder_list_label);
    idsecg = zeros(n_,1);
    iddd_ = 1:length(secname);
    for i_ = 1:n_
      iis = matches(secname, options.output_girder_list_label{i_});
      if any(iis)
        ii = iddd_(iis);
        idsecg(i_) = ii(1);
      end
    end
    grname = options.output_girder_list_label';
    return
  end
%--------------------------------------------------------------------------
  function [crname, idsecc] = find_section_column(secname)
    n_ = length(options.output_column_list_label);
    idsecc = zeros(n_,1);
    iddd_ = 1:length(secname);
    for i_ = 1:n_
      iis = matches(secname, options.output_column_list_label{i_});
      if any(iis)
        ii = iddd_(iis);
        idsecc(i_) = ii(1);
      end
    end
    crname = options.output_column_list_label';
    return
  end
%--------------------------------------------------------------------------
  function [grname, idsec] = sort_section_girder(secname)
    labels_ = unique(secname);
    n_ = length(labels_);

    % 最大長の検索
    nstrmax_ = 0;
    for i_ = 1:n_
      nstrmax_ = max(nstrmax_,length(labels_{i_}));
    end

    % パッディング
    labels_tmp = labels_;
    for i_ = 1:n_
      nstr_ = length(labels_{i_});
      labels_tmp{i_} = [labels_tmp{i_} blanks(nstrmax_-nstr_)];
    end

    % ソート
    [~, idsec] = sort(labels_tmp);
    grname = labels_(idsec);
    return
  end
end

