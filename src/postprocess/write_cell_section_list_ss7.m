function [gshead, gsbody, cshead, csbody, cbshead, cbsbody] = ...
  write_cell_section_list_ss7(secdim, com, result, options)
%write_cell_section_list_ss7 - SS7形式の断面リストセル配列を生成
%
%   [gshead, gsbody, cshead, csbody, cbshead, cbsbody] =
%     write_cell_section_list_ss7(secdim, com, result, options)
%   は、SS7形式の梁・柱・柱脚断面リストを生成する。
%
%   入力引数:
%     secdim  - 断面寸法配列 [nsec×ncol]
%     com     - 共通オブジェクト
%     result  - 解析結果構造体
%     options - オプション構造体
%
%   出力引数:
%     gshead  - 梁断面リストヘッダ
%     gsbody  - 梁断面リストボディ
%     cshead  - 柱断面リストヘッダ
%     csbody  - 柱断面リストボディ
%     cbshead - 柱脚断面リストヘッダ
%     cbsbody - 柱脚断面リストボディ

% 共通定数
nstory = com.nstory;
ncb = com.nseccb;

% 共通配列
secg = com.section.girder;
secc = com.section.column;
seclist = com.sectionList.list;
cstype = com.section.column.type;
secmgr = com.secmgr;
material = com.material;

% 梁断面リスト出力
ng = length(secg.name);
if isempty(options.output_girder_list_label)
  [grname, iddd] = sort_section_girder(secg.name);
else
  [grname, iddd] = find_section_girder(secg.name);
end
ngr = length(iddd);

% 出力準備
gshead = {'層', '梁符号', '添字', 'ハンチ', '', '鉄骨形状', ...
  '鉄骨登録形状', '', '', '', '', '', '材料', '', ''; ...
  '', '', '', '左端', '右端', '', '左端', 'タイプ左', '中央', ...
  'タイプ中', '右端', 'タイプ右', '左端', '中央', '右端'};
gsbody = cell(ngr*nstory,15);

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
      irow = irow+1;
      gsbody{irow,1} = secg.story_name{ig};
      gsbody{irow,2} = secg.name{ig};
      gsbody{irow,3} = format_subindex(secg.subindex{ig});
      gsbody{irow,4} = 0;
      gsbody{irow,5} = 0;
      type_name = secg.type_name{ig};
      if type_name == 'H'
        type_name = 'Ｈ';
      end
      gsbody{irow,6} = type_name;
      is = secg.idsec(ig);
      idslist = secdim(is, PRM.MAPPED_SECDIM_SLIST);
      idsection = secdim(is, PRM.MAPPED_SECDIM_SECTION);
      secglist = seclist{idslist};
      symbol = secglist.symbol{idsection};
      sdim = format_section_list_dim(secg.type(ig), secdim(is,:), symbol);
      sectype = normalize_ss7_steel_type_name(secglist.type{idsection});
      gsbody{irow,7} = sdim;
      gsbody{irow,8} = sectype;
      gsbody{irow,9} = sdim;
      gsbody{irow,10} = sectype;
      gsbody{irow,11} = sdim;
      gsbody{irow,12} = sectype;
      % 鉄骨材料（選択した候補断面が属するサブリストの材料）
      idsub = secmgr.secList.idsublist{idslist}(idsection);
      mat = material.name{secmgr.secList.idmaterial(idsub)};
      gsbody{irow,13} = mat;
      gsbody{irow,14} = mat;
      gsbody{irow,15} = mat;
    end
  end
end

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
cshead = {'階', '柱符号', '添字', '鉄骨形状', '鉄骨断面', '', ''; ...
  '', '', '', '', '登録形状', 'タイプX', '鉄骨材料'};
csbody = cell(ncr*nstory, 7);
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for icr = 1:ncr
    % 出力
    for ic=1:nc
      % 鉄骨柱（角形鋼管・円形鋼管・H形鋼）だけを書く。RC柱は対象外
      if cstype(ic)==PRM.RCRS
        continue
      end
      if secc.idstory(ic)~=ist || ~matches(secc.name{ic},crname{icr})
        continue
      end
      irow = irow+1;
      csbody{irow,1} = secc.floor_name{ic};
      csbody{irow,2} = secc.name{ic};
      csbody{irow,3} = format_subindex(secc.subindex{ic});
      % 鉄骨形状はSS7の柱の形状と同じ表記で、H形鋼柱はX方向強軸をＨ、
      % Y方向強軸をＩと書き、鋼管は断面リストの鉄骨形状をそのまま書く
      % （入力編 表7.1.3）。登録形状はH形鋼柱も同じ列に書く
      switch cstype(ic)
        case PRM.CWFS
          csbody{irow,4} = 'Ｈ';
        case PRM.CWFSI
          csbody{irow,4} = 'Ｉ';
        otherwise
          csbody{irow,4} = secc.type_name{ic};
      end
      is = secc.idsec(ic);
      idslist = secdim(is, PRM.MAPPED_SECDIM_SLIST);
      idsection = secdim(is, PRM.MAPPED_SECDIM_SECTION);
      secclist = seclist{idslist};
      symbol = secclist.symbol{idsection};
      sectype = secclist.type{idsection};
      sdim = format_section_list_dim(cstype(ic), secdim(is,:), symbol);
      csbody{irow,5} = sdim;
      csbody{irow,6} = sectype;
      % 鉄骨材料（選択した候補断面が属するサブリストの材料）
      idsub = secmgr.secList.idsublist{idslist}(idsection);
      csbody{irow,7} = material.name{secmgr.secList.idmaterial(idsub)};
    end
  end
end

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
  %find_section_girder - 出力制御ラベル順に梁符号と参照行を返す
  %
  %   入力引数:
  %     secname - 梁断面の符号セル配列
  %
  %   出力引数:
  %     grname - 出力ラベル順に並んだ符号
  %     idsecg - 各符号の secname における先頭行番号
    n_ = length(options.output_girder_list_label);
    idsecg = zeros(n_,1);
    for i_ = 1:n_
      iis = matches(secname, options.output_girder_list_label{i_});
      if any(iis)
        idsecg(i_) = find(iis, 1);
      end
    end
    grname = options.output_girder_list_label';
    return
  end
%--------------------------------------------------------------------------
  function [crname, idsecc] = find_section_column(secname)
  %find_section_column - 出力制御ラベル順に柱符号と参照行を返す
  %
  %   入力引数:
  %     secname - 柱断面の符号セル配列
  %
  %   出力引数:
  %     crname - 出力ラベル順に並んだ符号
  %     idsecc - 各符号の secname における先頭行番号
    n_ = length(options.output_column_list_label);
    idsecc = zeros(n_,1);
    for i_ = 1:n_
      iis = matches(secname, options.output_column_list_label{i_});
      if any(iis)
        idsecc(i_) = find(iis, 1);
      end
    end
    crname = options.output_column_list_label';
    return
  end
%--------------------------------------------------------------------------
  function [grname, idsec] = sort_section_girder(secname)
  %sort_section_girder - 梁符号を文字列ソートして返す
  %
  %   入力引数:
  %     secname - 梁断面の符号セル配列
  %
  %   出力引数:
  %     grname - 文字列ソート後の符号
  %     idsec  - ソート前の labels_ 内インデックス
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

