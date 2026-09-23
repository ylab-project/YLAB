classdef SectionListHandler < handle
  %SectionListHandler 断面リストの候補断面表を保持するクラス
  %   断面リスト名ごとに、入力ブロック「断面リスト」の各行（サブリスト）
  %   が指定するリストファイルの候補行を読み込み、同じ断面リスト名の行を
  %   入力順に縦へ連結した候補断面表を保持します。材料、コスト係数、
  %   コスト定数、フェーズ番号、タイプの絞込み条件はサブリスト単位で持ち、
  %   候補断面表の各行は idsublist で自分のサブリストを指します。
  %
  %   SectionListHandler プロパティ:
  %     listdir               - リストファイルの格納ディレクトリ
  %     name                  - 断面リスト名 {nlist×1}
  %     section_type          - 断面種別 [nlist×1]
  %     section_type_name     - 鉄骨形状名 {nlist×1}
  %     list                  - 候補断面表（table）{nlist×1}
  %     dimension_array       - 候補断面の寸法配列 {nlist×1}
  %     dimension_value_array - フェーズ別の寸法値の集合 {nlist×1}
  %     idsublist             - 候補断面→サブリスト {nlist×1}
  %     idmaterial            - サブリストの材料ID [nsublist×1]
  %     isSN                  - サブリストの材料がSN材か [nsublist×1]
  %     cost_factor           - サブリストのコスト係数 [nsublist×1]
  %     cost_constant         - サブリストのコスト定数 [nsublist×1]
  %     design_stress_factor  - サブリストの設計応力係数 [nsublist×1]
  %     idphase               - サブリストのフェーズ番号 [nsublist×1]
  %     type_name             - サブリストのタイプ絞込み条件 {nsublist×1}
  %
  %   SectionListHandler メソッド:
  %     registerList       - 断面リストブロックの各行を読み込む
  %     getDimension       - フェーズ内の候補断面の寸法配列を取得
  %     getDimensionValues - フェーズ内の寸法値の集合を取得
  %     getMaxIdPhase      - フェーズ番号の最大値を取得
  %
  %   参考:
  %     SectionManager, SectionStandardAccessor

  properties
    listdir               % リストファイルの格納ディレクトリ
    name                  % 断面リスト名 {nlist×1}
    section_type_name     % 鉄骨形状名 {nlist×1}
    section_type          % 断面種別 [nlist×1]
    list                  % 候補断面表（table）{nlist×1}
    dimension_array       % 候補断面の寸法配列 {nlist×1}
    dimension_value_array % フェーズ別の寸法値の集合 {nlist×1}
    idsublist             % 候補断面→サブリスト {nlist×1}、各[ncand×1]
    idmaterial            % サブリストの材料ID [nsublist×1]
    isSN                  % サブリストの材料がSN材か [nsublist×1]
    cost_factor           % サブリストのコスト係数 [nsublist×1]
    cost_constant         % サブリストのコスト定数 [nsublist×1]
    design_stress_factor  % サブリストの設計応力係数 [nsublist×1]
    idphase               % サブリストのフェーズ番号 [nsublist×1]
    type_name             % サブリストのタイプ絞込み条件 {nsublist×1}
  end

  properties(Dependent)
    nlist       % 断面リスト数
    nsublist    % サブリスト数（断面リストブロックのデータ行数）
    nsecOfList  % 断面リストごとの候補断面数 [nlist×1]
  end

  methods
    %----------------------------------------------------------------------
    function nlist = get.nlist(obj)
      nlist = length(obj.list);
    end
    %----------------------------------------------------------------------
    function nsublist = get.nsublist(obj)
      nsublist = length(obj.idphase);
    end
    %----------------------------------------------------------------------
    function nsecOfList = get.nsecOfList(obj)
      nsecOfList = zeros(obj.nlist,1);
      for i=1:obj.nlist
        nsecOfList(i) = size(obj.list{i},1);
      end
    end
    %----------------------------------------------------------------------
    function obj = SectionListHandler(listdir)
      obj.listdir = listdir;
    end
    %----------------------------------------------------------------------
    function obj = registerList(obj, section_list_name, section_type, ...
        section_type_name, idlist, file_name, idmaterial, cost_factor, ...
        cost_constant, design_stress_factor, isSN, idphase, type_name)
      %registerList 断面リストブロックの各行からリストファイルを読み込む
      %   入力引数:
      %     section_list_name - 断面リスト名 {nlist×1}（一意）
      %     section_type      - 断面種別 [nlist×1]
      %     section_type_name - 鉄骨形状名 {nlist×1}
      %     idlist            - サブリストが属する断面リスト [nsublist×1]
      %     file_name         - サブリストのリストファイル名 {nsublist×1}
      %     idmaterial, cost_factor, cost_constant, design_stress_factor,
      %     isSN, idphase, type_name
      %                       - サブリストごとの入力値 [nsublist×1]

      % 断面リスト単位とサブリスト単位の入力値
      obj.name = section_list_name;
      obj.section_type_name = section_type_name;
      obj.section_type = section_type;
      obj.idmaterial = idmaterial;
      obj.cost_factor = cost_factor;
      obj.cost_constant = cost_constant;
      obj.design_stress_factor = design_stress_factor;
      obj.isSN = isSN;
      obj.idphase = idphase;
      obj.type_name = type_name;

      % 候補断面表の作成
      nlist_ = length(section_list_name);
      obj.list = cell(nlist_,1);
      obj.dimension_array = cell(nlist_,1);
      obj.dimension_value_array = cell(nlist_,1);
      obj.idsublist = cell(nlist_,1);
      for i=1:nlist_
        % 同じ断面リスト名のサブリストを入力順に連結する
        idsubs = find(idlist(:)==i);
        list_subs = cell(numel(idsubs),1);
        nsubs = zeros(numel(idsubs),1);
        for k = 1:numel(idsubs)
          idsub = idsubs(k);
          file_ = fullfile(obj.listdir, file_name{idsub});
          opts = detectImportOptions(file_);
          opts.Delimiter = {','};
          opts.CommentStyle = '%';
          opts.VariableNamingRule ='preserve';
          list_sub = readtable(file_, opts);
          nsub = size(list_sub,1);
          isok = true(nsub,1);
          label_ = list_sub.label;
          type_ = list_sub.type;
          type_name_ = type_name{idsub};
          if iscell(label_)
            for j=1:nsub
              if ~isempty(label_{j})
                if label_{j}(1) == '%'
                  isok(j) = false;
                end
              end
              if ~isempty(type_name_)
                if ~strcmp(type_{j}, type_name_)
                  isok(j) = false;
                end
              end
            end
          else
            list_sub.label = cellstr(num2str(label_));
          end
          list_sub = list_sub(isok,:);
          if isempty(list_sub)
            throw_warn('List', 'EmptyAfterFilter', ...
              section_list_name{i}, type_name_, file_name{idsub});
          end
          % 個別処理（候補が0行でも列構成を揃える）
          switch obj.section_type(i)
            case PRM.WFS
              % H形鋼の場合
              is_small_H = list_sub.H<200;
              Hnominal = list_sub.H;
              Hnominal(is_small_H) = round(list_sub.H(is_small_H)/25)*25;
              Hnominal(~is_small_H) = round(list_sub.H(~is_small_H)/50)*50;
              list_sub.Hnominal = Hnominal;
              list_sub.Bnominal = round(list_sub.B/25)*25;
            case PRM.BRB
              % BRBの場合
              n = size(list_sub,1);
              dimension_ = zeros(n,4);
              for j=1:n
                sss = textscan(list_sub.symbol{j}, '%s %f %f %f', ...
                  'Delimiter',{'-','(',')'});
                type = PRM.get_id_ubb_type(sss{1});
                dimension_(j,1:4) = [type sss{2} sss{3} sss{4}];
              end
              list_sub.dimension = dimension_;
            case PRM.HSR
              % HSR（円形鋼管）の場合
              % CSVの列構成: label, type, symbol, D, t
              % dimensionとして[D, t]を格納
              n = size(list_sub,1);
              dimension_ = zeros(n,2);
              dimension_(:,1) = list_sub.D;     % 外径
              dimension_(:,2) = list_sub.t;     % 板厚
              list_sub.dimension = dimension_;
            case PRM.TB
              % 引張ブレースの場合
              % dimension: [shape_code, A(mm2), Ae(mm2)]
              n = size(list_sub, 1);
              dimension_ = zeros(n, 3);
              for j = 1:n
                dimension_(j, 1) = ...
                  PRM.get_tb_shape_code(list_sub.label{j});
              end
              dimension_(:, 2) = list_sub.A * 100; % cm2→mm2
              dimension_(:, 3) = list_sub.Ae * 100; % cm2→mm2
              list_sub.dimension = dimension_;
          end
          list_subs{k} = list_sub;
          nsubs(k) = size(list_sub,1);
        end
        obj.list{i} = vertcat(list_subs{:});
        % repelemはスカラー入力で行を返すため列ベクトルにそろえる
        obj.idsublist{i} = reshape(repelem(idsubs, nsubs), [], 1);
        if isempty(obj.list{i})
          obj.dimension_array{i} = [];
        else
          switch obj.section_type(i)
            case {PRM.WFS, PRM.BWFS}
              obj.dimension_array{i} = table2array(obj.list{i}(:,4:10));
            case {PRM.HSS, PRM.BHSS}
              obj.dimension_array{i} = table2array(obj.list{i}(:,4:6));
            case {PRM.BRB, PRM.HSR, PRM.BHSR, PRM.TB}
              obj.dimension_array{i} = obj.list{i}.dimension;
            otherwise
              obj.dimension_array{i} = [];
          end
        end
        obj.dimension_value_array{i} = obj.createDimensionValueArray(i);
      end
      return
    end
    %----------------------------------------------------------------------
    function values = createDimensionValueArray(obj, idList)
      %createDimensionValueArray フェーズ別に寸法値の集合を作る
      %   フェーズ番号は候補断面が属するサブリストの値を使う。
      secdim = obj.dimension_array{idList};
      idphase_ = obj.idphase(obj.idsublist{idList});
      phase = unique(idphase_);
      values.phase = phase;
      values.column = cell(numel(phase), size(secdim, 2));
      for i = 1:numel(phase)
        is_phase = idphase_ <= phase(i);
        for j = 1:size(secdim, 2)
          values.column{i, j} = unique(secdim(is_phase, j))';
        end
      end
      return
    end
    %----------------------------------------------------------------------
    function values = getDimensionValues(obj, idList, idColumn, idPhase)
      cache = obj.dimension_value_array{idList};
      if nargin == 3
        idPhase = inf;
      end
      id = find(cache.phase <= idPhase, 1, 'last');
      if isempty(id)
        values = [];
      else
        values = cache.column{id, idColumn};
      end
      return
    end
    %----------------------------------------------------------------------
    function n = getMaxIdPhase(obj)
      %getMaxIdPhase - 全サブリストのフェーズ番号の最大値を返す
      n = max([0; obj.idphase(:)]);
      return
    end
    %----------------------------------------------------------------------
    function [dimension, idsection] = getDimension(obj, idList, idPhase)
      %getDimension フェーズ内の候補断面の寸法配列を返す
      %   フェーズ番号が idPhase 以下のサブリストに属する候補断面の
      %   寸法配列と、各行に対応する候補断面表の行番号を返す。
      dimension = [];
      idsection = zeros(0,1);
      if isempty(obj.dimension_array{idList})
        return
      end
      is_phase = obj.idphase(obj.idsublist{idList}) <= idPhase;
      dimension = obj.dimension_array{idList}(is_phase, :);
      idsection = find(is_phase);
      return
    end
  end
end
