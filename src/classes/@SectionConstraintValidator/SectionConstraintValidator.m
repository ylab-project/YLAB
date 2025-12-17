classdef SectionConstraintValidator < handle
  %SectionConstraintValidator 断面制約検証クラス
  %   SectionConstraintValidatorは、断面の制約チェック、有効性検証、
  %   上下限値管理を担当します。SectionManagerから制約関連の責務を
  %   分離したクラスです。
  %
  %   SectionConstraintValidator プロパティ:
  %     validSectionFlagCell - 有効断面フラグ {nlist×1} cell配列
  %     isVarofSlist - 変数-断面リストマッピング [nxvar×nlist]
  %     columnBaseList - 柱脚リスト [1×ncbs] 構造体配列
  %     nlist - 断面リスト数
  %     nwfs - WFS断面数
  %     nxvar - 変数総数
  %
  %   SectionConstraintValidator メソッド:
  %     limitJbsSection - JBS制限チェック
  %     limitSlrSection - 細長比制限チェック
  %     limitWtRatioSection - 幅厚比制限チェック
  %     initValidSectionFlagCell - 有効断面フラグ初期化
  %     extractValidSectionFlags - 有効断面フラグ抽出
  %     getLowerBounds - 下限値取得
  %     getUpperBounds - 上限値取得
  %
  %   例:
  %     validator = SectionConstraintValidator(secList, ...
  %       standardAccessor, isVarofSlist, idMapper, columnBaseList);
  %     bounds = validator.getLowerBounds(1);
  %
  %   参考:
  %     SectionManager, SectionPropertyCalculator, IdMapper

  properties (Access = private)
    % 内部実装の詳細
    validSectionFlagCell_   % 断面リストごとの有効性フラグ {nlist×1} cell配列
    secList_                % SectionListHandlerへの参照
    standardAccessor_       % SectionStandardAccessorへの参照
    idMapper_               % IdMapperインスタンス
  end

  properties (SetAccess = private)
    % SectionManagerがDependentで参照するもの
    isVarofSlist            % 変数-断面リストマッピング [nxvar×nlist]
    columnBaseList          % 柱脚リスト [1×ncbs] 構造体配列
  end

  properties (Dependent)
    nlist                   % 断面リスト数
    nwfs                    % WFS断面数
    nxvar                   % 変数総数
    validSectionFlagCell    % 有効断面フラグ全体 {nlist×1} cell配列
    % IdMapperへの委譲プロパティ
    idvar2vtype             % 変数タイプマッピング [nxvar×1]
    idsec2slist             % 断面→断面リストマッピング [nsec×1]
    idsec2stype             % 断面→断面タイプマッピング [nsec×1]
    idsec2wfs               % 断面→WFS断面マッピング [nsec×1]
    idsec2srep              % 断面→代表断面マッピング [nsec×1]
    idme2sec                % 部材→断面マッピング [nme×1]
  end

  methods
    function obj = SectionConstraintValidator(secList, ...
        standardAccessor, isVarofSlist, idMapper, columnBaseList)
      %SectionConstraintValidator コンストラクタ
      %   validator = SectionConstraintValidator(secList, ...
      %     standardAccessor, isVarofSlist, idMapper, columnBaseList) は、
      %   断面制約検証オブジェクトを作成します。
      %
      %   入力引数:
      %     secList - SectionListHandlerオブジェクト
      %     standardAccessor - SectionStandardAccessorオブジェクト
      %     isVarofSlist - 変数-断面リストマッピング [nxvar×nlist] 論理値行列
      %     idMapper - IdMapperオブジェクト
      %     columnBaseList - 柱脚リスト [1×ncbs] 構造体配列
      %
      %   例:
      %     validator = SectionConstraintValidator(secList, ...
      %       standardAccessor, isVarofSlist, idMapper, columnBaseList);

      if nargin < 5
        error('SectionConstraintValidator:Constructor', ...
          ['secList, standardAccessor, isVarofSlist, idMapper, ' ...
           'columnBaseListが必要です']);
      end

      % プロパティ初期化
      obj.secList_ = secList;
      obj.standardAccessor_ = standardAccessor;
      obj.isVarofSlist = isVarofSlist;
      obj.columnBaseList = columnBaseList;
      obj.validSectionFlagCell_ = {};
      obj.idMapper_ = idMapper;
    end

    %% get.nlist
    function nlist_ = get.nlist(obj)
      % 断面リスト数を取得
      if ~isempty(obj.secList_)
        nlist_ = obj.secList_.nlist;
      else
        nlist_ = 0;
      end
    end

    %% get.nwfs
    function nwfs_ = get.nwfs(obj)
      % WFS断面数を取得
      nwfs_ = obj.idMapper_.nwfs;
    end

    %% get.nxvar
    function nxvar_ = get.nxvar(obj)
      % 変数総数を取得
      nxvar_ = length(obj.idMapper_.idvar2vtype);
    end
    
    %% get.validSectionFlagCell
    function val = get.validSectionFlagCell(obj)
      % 有効断面フラグ全体を取得（cell配列）
      val = obj.validSectionFlagCell_;
    end
    
    %% set.validSectionFlagCell
    function set.validSectionFlagCell(obj, val)
      % 有効断面フラグ全体を設定（cell配列）
      if ~iscell(val)
        error('SectionConstraintValidator:InvalidInput', ...
          'validSectionFlagCellはcell配列である必要があります');
      end
      obj.validSectionFlagCell_ = val;
    end

    %% IdMapperへの委譲プロパティ
    function val = get.idvar2vtype(obj)
      val = obj.idMapper_.idvar2vtype;
    end
    
    function val = get.idsec2slist(obj)
      % 1列版を返す（断面リストIDのみ）
      val = obj.idMapper_.idSectionList;
    end
    
    function val = get.idsec2stype(obj)
      val = obj.idMapper_.idsec2stype;
    end
    
    function val = get.idsec2wfs(obj)
      % idsec2wfsを計算
      val = obj.idMapper_.mapSectionToWfs();
    end
    
    function val = get.idsec2srep(obj)
      val = obj.idMapper_.idsec2srep;
    end
    
    function val = get.idme2sec(obj)
      val = obj.idMapper_.idme2sec;
    end

    %% isSecListEmpty
    function isEmpty = isSecListEmpty(obj)
      % secListが空かどうかを確認
      %
      % Returns:
      %   isEmpty - 空の場合true

      isEmpty = isempty(obj.secList_) || obj.nlist == 0;
    end

    % validateSectionListId - 外部ファイルに定義
    %% initValidSectionFlagCell
    function initValidSectionFlagCell(obj)
      % 有効断面フラグセルを初期化
      %
      % 全断面リストに対して有効フラグを初期化する。
      % 初期状態では全ての断面を有効とする。
      % WFS断面: nwfs×nsecOfList、HSS/BRB断面: 1×nsecOfList の配列
      
      nlist_ = obj.nlist;
      obj.validSectionFlagCell_ = cell(nlist_, 1);
      nwfs_ = obj.nwfs;  % 0でも許容（0行の行列を作る）
      nsecOfList = obj.secList_.nsecOfList;
      sectionType = obj.secList_.section_type;
      
      for idsList = 1:nlist_
        % 断面タイプに応じたサイズで初期化
        switch sectionType(idsList)
          case PRM.WFS
            % WFS断面: nwfs×nsecOfList
            obj.validSectionFlagCell_{idsList} = true(nwfs_, nsecOfList(idsList));
          case {PRM.HSS, PRM.HSR, PRM.BRB}
            % HSS/BRB断面: 1×nsecOfList
            obj.validSectionFlagCell_{idsList} = true(1, nsecOfList(idsList));
          otherwise
            error('SectionConstraintValidator:UnknownSectionType', ...
              '未知の断面タイプ: %d', sectionType(idsList));
        end
      end
    end
    
  end

  methods (Access = private)
    % 今後privateメソッドが必要になった場合はここに追加
  end
end