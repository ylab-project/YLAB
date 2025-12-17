classdef SectionListHandler < handle
  properties
    listdir
    name
    section_type_name
    material_name
    % file_name
    section_type
    idmaterial
    list
    % isValid
    cost_factor
    design_stress_factor
    isSN
    idphase
    type_name
    idsublist
    nsublist
  end

  properties(Dependent)
    nlist
    nwfsList
    nhssList
    nsecOfList
    dimension
  end

  methods
    %----------------------------------------------------------------------
    function nlist = get.nlist(obj)
      nlist = length(obj.list);
    end
    %----------------------------------------------------------------------
    function nwfsList = get.nwfsList(obj)
      nwfsList = sum(obj.section_type==PRM.WFS);
    end
    %----------------------------------------------------------------------
    function nhssList = get.nhssList(obj)
      nhssList = sum(obj.section_type==PRM.HSS);
    end
    %----------------------------------------------------------------------
    function dimension = get.dimension(obj)
      dimension = cell(obj.nlist,1);
      for id=1:obj.nlist
        dimension{id} = obj.getDimension(id);
      end
    end
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
    function obj = registerList(obj, ...
        section_type, section_type_name, nlist, ...
        section_list_name, material_name, ...
        file_name, idmaterial, cost_factor, design_stress_factor, ...
        isSN, idphase, type_name)

      % プロパティの保存
      obj.name = section_list_name;
      obj.section_type_name = section_type_name;
      obj.material_name = material_name;
      obj.section_type = section_type;

      % リストの保存
      nlistset = size(file_name,1);
      obj.list = cell(nlistset,1);
      % obj.isValid = cell(nlistset,1);
      obj.idmaterial = cell(nlistset,1);
      obj.cost_factor = cell(nlistset,1);
      obj.design_stress_factor = cell(nlistset,1);
      obj.isSN = cell(nlistset,1);
      obj.idsublist = cell(nlistset,1);
      idsub = 0;
      for i=1:nlistset
        for il=1:nlist(i)
          idsub = idsub+1;
          file_ = fullfile(obj.listdir, file_name{i,il});
          opts = detectImportOptions(file_);
          opts.Delimiter = {','};
          % opts.DataLines = [1,inf];
          opts.CommentStyle = '%';
          opts.VariableNamingRule ='preserve';
          list_ = readtable(file_, opts);
          nlist_ = size(list_,1);
          isok = true(nlist_,1);
          label_ = list_.label;
          type_ = list_.type;
          type_name_ = type_name{i,il};
          if iscell(label_)
            for j=1:nlist_
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
            list_.label = cellstr(num2str(label_));
          end
          list_ = list_(isok,:);
          % 個別処理
          switch obj.section_type(i)
            case PRM.WFS
              % H形鋼の場合
              is_small_H = list_.H<200;
              Hnominal = list_.H;
              Hnominal(is_small_H) = round(list_.H(is_small_H)/25)*25;
              Hnominal(~is_small_H) = round(list_.H(~is_small_H)/50)*50;
              Hnominal = table(Hnominal);
              Bnominal = round(list_.B/25)*25;
              Bnominal = table(Bnominal);
              list_ = [list_ Hnominal Bnominal];
            case PRM.BRB
              % BRBの場合
              n = size(list_,1);
              dimension_ = zeros(n,4);
              for j=1:n
                sss = textscan(list_.symbol{j}, ...
                  '%s %f %f %f','Delimiter',{'-','(',')'});
                type = PRM.get_id_ubb_type(sss{1});
                dimension_(j,1:4) = [type sss{2} sss{3} sss{4}];
              end
              list_.dimension = dimension_;
            case PRM.HSR
              % HSR（円形鋼管）の場合
              % CSVの列構成: label, type, symbol, D, t
              % dimensionとして[D, t]を格納
              n = size(list_,1);
              dimension_ = zeros(n,2);
              dimension_(:,1) = list_.D;     % 外径
              dimension_(:,2) = list_.t;     % 板厚
              list_.dimension = dimension_;
          end
          nlist_ = size(list_,1);
          idsublist_ = idsub*(ones(nlist_,1));
          if il==1
            % 新規作成
            obj.list{i} = list_;
            % obj.isValid{i} = true(1,nlist_);
            obj.idmaterial{i} = idmaterial(i,il)*ones(1,nlist_);
            obj.cost_factor{i} = cost_factor(i,il)*ones(1,nlist_);
            obj.design_stress_factor{i} = design_stress_factor(i,il)...
              *ones(1,nlist_);
            if isSN(i,il)
              obj.isSN{i} = true(1,nlist_);
            else
              obj.isSN{i} = false(1,nlist_);
            end
            obj.idphase{i} = idphase(i,il)*ones(1,nlist_);
            obj.idsublist{i} = idsublist_;
          else
            % 追加
            obj.list{i} = [obj.list{i}; list_];
            % obj.isValid{i} = [obj.isValid{i} true(1,nlist_)];
            obj.idmaterial{i} = [obj.idmaterial{i} ...
              idmaterial(i,il)*ones(1,nlist_)];
            obj.cost_factor{i} = [obj.cost_factor{i} ...
              cost_factor(i,il)*ones(1,nlist_)];
            obj.design_stress_factor{i} = [obj.design_stress_factor{i} ...
              design_stress_factor(i,il)*ones(1,nlist_)];
            if isSN(i,il)
              obj.isSN{i} = [obj.isSN{i} true(1,nlist_)];
            else
              obj.isSN{i} = [obj.isSN{i} false(1,nlist_)];
            end
            obj.idphase{i} = [obj.idphase{i} idphase(i,il)*ones(1,nlist_)];
            obj.idsublist{i} = [obj.idsublist{i}; idsublist_];
          end
        end
        obj.nsublist = idsub;
      end
      return
    end
    %----------------------------------------------------------------------
    function dimension = getDimension(obj, idList, idPhase)
      dimension = [];      
      id = idList;
      stype = obj.section_type(id);
      if nargin==2
        idPhase = inf;
      end
      switch stype
        case PRM.WFS
          dimension = table2array(obj.list{id}(...
            obj.idphase{id}<=idPhase,4:10));
        case PRM.HSS
          dimension = table2array(obj.list{id}(...
            obj.idphase{id}<=idPhase,4:6));
        case PRM.BRB
          % symbol = obj.list{id}.symbol;
          % n = size(symbol,1);
          % dimension = zeros(n,4);
          % for i=1:n
          %   sss = textscan(symbol{i}, ...
          %     '%s %f %f %f','Delimiter',{'-','(',')'});
          %   ubb_type = PRM.get_id_ubb_type(sss{1});
          %   dimension(i,1:4) = [ubb_type sss{2} sss{3} sss{4}];
          % end
          dimension = obj.list{id}.dimension;
          dimension = dimension(obj.idphase{id}<=idPhase,:);
        case PRM.HSR
          % HSR断面の寸法取得
          dimension = obj.list{id}.dimension;
          dimension = dimension(obj.idphase{id}<=idPhase,:);
      end
      return
    end
    %----------------------------------------------------------------------
    function costFactor = getCostFactor(obj, idList)
      id = idList;
      costFactor = obj.cost_factor{id}(obj.isValid{id});
    end

    %----------------------------------------------------------------------
    function idMaterial = getIdMaterial(obj, idList)
      id = idList;
      idMaterial = obj.idmaterial{id};
    end
  end
end


