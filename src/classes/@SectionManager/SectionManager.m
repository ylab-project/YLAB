classdef SectionManager < handle
%SectionManager 断面管理の中心的なファサードクラス
%   SectionManagerは、断面関連の機能を統合的に管理するファサード
%   クラスです。断面の規格値取得、制約検証、材料特性、ID変換など
%   の機能を専門クラスに委譲し、統一的なインターフェースを提供します。
%
%   主な委譲先:
%     PropertyCalculator - 材料特性とコスト計算
%     ConstraintValidator - 制約条件の検証
%     StandardAccessor - 断面規格値の取得
%     IdMapper - ID変換とマッピング
%
%   SectionManager プロパティ:
%     idHgap2var - ギャップ変数IDマッピング（neighborSearcher経由）
%     idHgap2sec - ギャップ断面IDマッピング（neighborSearcher経由）
%     dimension - 断面寸法配列
%     idphase - フェーズID（standardAccessor経由）
%     secList - 断面リストハンドラ
%
%   参考:
%     SectionPropertyCalculator, SectionConstraintValidator,
%     SectionStandardAccessor, IdMapper
  
  % properties節は削除（idphaseはDependentに移動）
  properties(Access=private)
    % SectionPropertyCalculatorインスタンス（内部用）
    propertyCalculator_
    % SectionConstraintValidatorインスタンス（内部用）
    constraintValidator_
    standardAccessor_       % SectionStandardAccessorインスタンス（内部用）
    idMapper_               % IdMapperインスタンス（内部用）
    neighborSearcher_       % SectionNeighborSearcherインスタンス（内部用）
  end
  properties(Access=public)
    secList
  end
  properties(Dependent, SetAccess=private)
    %% 内部オブジェクトへのアクセス（テスト用）
    propertyCalculator
    constraintValidator
    standardAccessor
    neighborSearcher
    idMapper
  end
  properties(Dependent)
    %% 断面関連
    idphase       % フェーズID（standardAccessorから取得）
    dimension     % 全断面のdimension配列（neighborSearcherから取得）
    
    %% ギャップ関連（neighborSearcherから取得）
    idHgap2var    % ギャップ変数IDマッピング
    idHgap2sec    % ギャップ断面IDマッピング
    
    %% 変数IDマッピング（IdMapperから取得）
    idH2var       % WFS断面H寸法の変数ID配列
    idB2var       % WFS断面B寸法の変数ID配列
    idtw2var      % WFS断面tw寸法の変数ID配列
    idtf2var      % WFS断面tf寸法の変数ID配列
    idD2var       % HSS断面D寸法の変数ID配列
    idt2var       % HSS断面t寸法の変数ID配列
    idBrb1_var    % BRB断面V1の変数ID配列
    idBrb2_var    % BRB断面V2の変数ID配列
    idme2mtype    % 部材→部材タイプマッピング
    idsec2var     % 断面→変数マッピング
    idsrep2sec    % 代表断面→断面マッピング
    idvar2srep    % 変数→代表断面マッピング
    isVarofSlist  % 変数-断面リストマッピング [nxvar×nlist]
    
    %% 材料データ（PropertyCalculatorの実体を参照）
    material
    
    %% 制約関連データ（ConstraintValidatorの実体を参照）
    idvar2vtype
    idSectionList  % 断面→断面リストID [nsec×1]（静的）
    idsec2stype
    idsec2wfs
    idsec2srep
    idme2sec
    isValidSectionOfSlist_  % 有効断面リスト
    column_base_list        % 柱脚リスト
    
    %% 断面数関連
    nxvar
    nsec, nhss, nwfs, nrcrs, nbrbs
    nsrep, nrephss, nrepwfs, nreprcrs, nrepbrbs
    nme, nmewfs, nmehss, nmercrs
    nlist
    
    %% 上下限
    lb, ub
    
    %% ID変換マッピング
    % 部材→断面
    idme2stype, idme2var
    % 断面→タイプ別
    idsec2hss, idsec2rcrs, idsec2brbs
    % タイプ別→断面（逆変換）
    idwfs2sec, idhss2sec, idbrbs2sec, idrcrs2sec
    % タイプ別→代表断面
    idhss2rephss, idwfs2repwfs, idrcrs2reprcrs, idbrbs2repbrbs
    % 代表断面関係
    idsrep2stype, idsrep2var
    idrephss2sec, idrephss2var, idrephss2hss
    idrepwfs2sec, idrepwfs2var, idrepwfs2wfs
    idreprcrs2sec, idreprcrs2rcrs
    idrepbrbs2sec, idrepbrbs2var, idrepbrbs2brbs
    % 断面リスト関係
    idwfs2slist, idhss2slist, idbrbs2slist
  end
  
  %% Static methods
  methods (Static)
    function [upsec, dwsec] = findUpDownWfsThick(secwfs, ...
      twortf, seclist, options)
      % WFS断面の板厚増減を探索（SectionNeighborSearcherに委譲）
      [upsec, dwsec] = SectionNeighborSearcher.findUpDownWfsThick(...
        secwfs, twortf, seclist, options);
    end
    
    function [upsec, dwsec] = findUpDownHssThick(sechss, seclist, options)
      % HSS断面の板厚増減を探索（SectionNeighborSearcherに委譲）
      [upsec, dwsec] = SectionNeighborSearcher.findUpDownHssThick(...
        sechss, seclist, options);
    end
    
    function idsec2slist = getSectionListMapping(secdim)
      % 断面リストID/断面IDマッピングを取得（委譲）
      idsec2slist = SectionNeighborSearcher.getSectionListMapping(secdim);
    end
  end
  methods
    %% idphaseのgetter/setter（standardAccessorに委譲）
    function val = get.idphase(secmgr)
      % フェーズIDをstandardAccessorから取得
      val = secmgr.standardAccessor_.idPhase;
    end
    
    function set.idphase(secmgr, val)
      % フェーズIDと現在フェーズ用検索配列を同期
      secmgr.standardAccessor_.idPhase = val;
      secmgr.constraintValidator_.updateValidSectionFlagCell(val);
    end
    
    %% neighborSearcherから取得するプロパティのgetter
    function val = get.dimension(secmgr)
      % 全断面のdimension配列をneighborSearcherから取得
      if ~isempty(secmgr.neighborSearcher_)
        val = secmgr.neighborSearcher_.dimension;
      else
        val = [];
      end
    end
    
    function val = get.idHgap2var(secmgr)
      % ギャップ変数IDマッピングをneighborSearcherから取得
      if ~isempty(secmgr.neighborSearcher_)
        val = secmgr.neighborSearcher_.idHgap2var;
      else
        val = [];
      end
    end
    
    function val = get.idHgap2sec(secmgr)
      % ギャップ断面IDマッピングをneighborSearcherから取得
      if ~isempty(secmgr.neighborSearcher_)
        val = secmgr.neighborSearcher_.idHgap2sec;
      else
        val = [];
      end
    end
    
    %% ConstraintValidatorから取得するプロパティのgetter
    function isValidSectionOfSlist = get.isValidSectionOfSlist_(secmgr)
      % 有効断面リストを取得（SectionConstraintValidatorから）
      if ~isempty(secmgr.constraintValidator_)
        isValidSectionOfSlist = ...
          secmgr.constraintValidator_.validSectionFlagCell;
      else
        % 初期化されていない場合は空のcell配列を返す
        isValidSectionOfSlist = {};
      end
    end
    
    function set.isValidSectionOfSlist_(secmgr, value)
      % 有効断面リストを設定（SectionConstraintValidatorへ）
      if ~isempty(secmgr.constraintValidator_)
        % Dependentプロパティへの代入
        secmgr.constraintValidator_.validSectionFlagCell = value;
      else
        error('SectionManager:NoConstraintValidator', ...
          'constraintValidatorが初期化されていません');
      end
    end
    
    %% IdMapperから取得するプロパティのgetter
    function nx = get.nxvar(secmgr)
      % 変数の総数をIdMapperから取得
      if ~isempty(secmgr.idMapper_)
        nx = secmgr.idMapper_.nxvar;
      else
        nx = 0;
      end
    end
    
    function val = get.idvar2vtype(secmgr)
      % IdMapperから直接取得
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idvar2vtype;
      else
        val = [];
      end
    end
    
    function val = get.idSectionList(secmgr)
      % IdMapperから静的な1列版を取得
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idSectionList;
      else
        val = [];
      end
    end
    
    function val = get.idsec2stype(secmgr)
      % IdMapperから直接取得
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idsec2stype;
      else
        val = [];
      end
    end
    
    function val = get.idsec2srep(secmgr)
      % IdMapperから直接取得
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idsec2srep;
      else
        val = [];
      end
    end
    
    function val = get.idH2var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idH2var;
      else
        val = [];
      end
    end
    
    function val = get.idB2var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idB2var;
      else
        val = [];
      end
    end
    
    function val = get.idtw2var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idtw2var;
      else
        val = [];
      end
    end
    
    function val = get.idtf2var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idtf2var;
      else
        val = [];
      end
    end
    
    function val = get.idD2var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idD2var;
      else
        val = [];
      end
    end
    
    function val = get.idt2var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idt2var;
      else
        val = [];
      end
    end
    
    function val = get.idBrb1_var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idBrb1_var;
      else
        val = [];
      end
    end
    
    function val = get.idBrb2_var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idBrb2_var;
      else
        val = [];
      end
    end
    
    function val = get.idme2mtype(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idme2mtype;
      else
        val = [];
      end
    end
    
    function val = get.idsec2var(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idsec2var;
      else
        val = [];
      end
    end
    
    function val = get.idsrep2sec(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idsrep2sec;
      else
        val = [];
      end
    end
    
    function val = get.idvar2srep(secmgr)
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idvar2srep;
      else
        val = [];
      end
    end
    
    function isVarofSlist = get.isVarofSlist(secmgr)
      % 変数-断面リストマッピングをIdMapperから取得
      if ~isempty(secmgr.idMapper_)
        isVarofSlist = secmgr.idMapper_.isVarofSlist;
      else
        isVarofSlist = [];
      end
    end
    
    function val = get.idme2sec(secmgr)
      % IdMapperから直接取得
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idme2sec;
      else
        val = [];
      end
    end
    
    function val = get.column_base_list(secmgr)
      % ConstraintValidatorの実体を参照（columnBaseListを返す）
      if ~isempty(secmgr.constraintValidator_)
        val = secmgr.constraintValidator_.columnBaseList;
      else
        val = [];
      end
    end
    
    %% 断面数関連のDependentプロパティgetter
    function nsec = get.nsec(secmgr)
      nsec = length(secmgr.idsec2stype);
    end
    function nwfs = get.nwfs(secmgr)
      nwfs = sum(secmgr.idsec2stype==PRM.WFS);
    end
    function nhss = get.nhss(secmgr)
      nhss = sum(secmgr.idsec2stype==PRM.HSS);
    end
    function nrcrs = get.nrcrs(secmgr)
      nrcrs = sum(secmgr.idsec2stype==PRM.RCRS);
    end
    function nbrbs = get.nbrbs(secmgr)
      nbrbs = sum(secmgr.idsec2stype==PRM.BRB);
    end
    %---
    function nme = get.nme(secmgr)
      nme = secmgr.nmewfs+secmgr.nmehss+secmgr.nmercrs;
    end
    function nmewfs = get.nmewfs(secmgr)
      nmewfs = sum(secmgr.idme2stype==PRM.WFS);
    end
    function nmehss = get.nmehss(secmgr)
      nmehss = sum(secmgr.idme2stype==PRM.HSS);
    end
    function nmercrs = get.nmercrs(secmgr)
      nmercrs = sum(secmgr.idme2stype==PRM.RCRS);
    end
    %---
    function nrepsec = get.nsrep(secmgr)
      nrepsec = size(secmgr.idsrep2sec,1);
    end
    function nrephss = get.nrephss(secmgr)
      nrephss = length(secmgr.idrephss2hss);
    end
    function nrepwfs = get.nrepwfs(secmgr)
      nrepwfs = length(secmgr.idrepwfs2wfs);
    end
    function nreprcrs = get.nreprcrs(secmgr)
      nreprcrs = length(secmgr.idreprcrs2rcrs);
    end
    function nrepbrbs = get.nrepbrbs(secmgr)
      nrepbrbs = length(secmgr.idrepbrbs2brbs);
    end
    
    function nlist = get.nlist(secmgr)
      nlist = secmgr.secList.nlist;
    end
    
    %% 内部オブジェクトへのアクセス用getter
    function calculator = get.propertyCalculator(secmgr)
      calculator = secmgr.propertyCalculator_;
    end
    function validator = get.constraintValidator(secmgr)
      validator = secmgr.constraintValidator_;
    end
    
    function accessor = get.standardAccessor(secmgr)
      accessor = secmgr.standardAccessor_;
    end
    
    function searcher = get.neighborSearcher(secmgr)
      searcher = secmgr.neighborSearcher_;
    end
    
    function mapper = get.idMapper(secmgr)
      mapper = secmgr.idMapper_;
    end

    %% 断面リスト操作（直接実装）
    function setSectionList(secmgr, secList)
      secmgr.secList = secList;
    end
    % function setSectionIsValid(secmgr, idslist, isValid)
    %   secmgr.secList.isValid{idslist} = isValid;
    % end
    function sectionType = getSectionType(secmgr, idlist)
      sectionType = secmgr.secList.section_type(idlist);
    end
    function nsublist = getNumSectionSubList(secmgr)
      nsublist = secmgr.secList.nsublist;
    end
    
    %% StandardAccessorへの委譲（規格値取得）
    % 規格値（実寸）取得
    function st = getHst(secmgr, idslist)
      st = secmgr.standardAccessor.getStandardH(idslist);
    end
    function st = getBst(secmgr, idslist)
      st = secmgr.standardAccessor.getStandardB(idslist);
    end
    function st = getTwst(secmgr, idslist)
      st = secmgr.standardAccessor.getStandardTw(idslist);
    end
    function st = getTfst(secmgr, idslist)
      st = secmgr.standardAccessor.getStandardTf(idslist);
    end
    function st = getDst(secmgr, id)
      st = secmgr.standardAccessor.getStandardD(id);
    end
    function st = getTst(secmgr, idslist)
      st = secmgr.standardAccessor.getStandardT(idslist);
    end
    function st = getBrb1st(secmgr, idslist)
      st = secmgr.standardAccessor.getStandardV1(idslist);
    end
    function st = getBrb2st(secmgr, idslist)
      st = secmgr.standardAccessor.getStandardV2(idslist);
    end

    % 公称値（呼び寸）取得
    function Hnominal = getHnominal(secmgr, idslist)
      Hnominal = secmgr.standardAccessor.getNominalH(idslist);
    end
    function Bnominal = getBnominal(secmgr, idslist)
      Bnominal = secmgr.standardAccessor.getNominalB(idslist);
    end

    % 変数関連情報取得
    function idslist = getIdSlistofVar(secmgr, idvar)
      % 変数が使用される断面リストIDを取得
      idslist = secmgr.idMapper_.getIdSlistofVar(idvar);
    end
    function vset = getNominalValueSetofVar(secmgr, idvar)
      % 変数の公称値セットを取得
      vset = secmgr.standardAccessor.getNominalValueSetofVar(idvar, ...
        secmgr.idMapper_, secmgr.idsec2var);
    end
    
    %% ConstraintValidatorへの委譲（制約関連）
    % 上下限値取得（全断面リストの統合値）
    function lb = get.lb(secmgr)
      % 全断面リストの下限値を統合取得
      lb = secmgr.constraintValidator_.getGlobalLowerBounds();
    end
    
    function ub = get.ub(secmgr)
      % 全断面リストの上限値を統合取得
      ub = secmgr.constraintValidator_.getGlobalUpperBounds();
    end
    
    %% ID変換用Dependentプロパティ（計算またはIdMapper委譲）
    % 部材->断面タイプ, 変数
    function idme2stype = get.idme2stype(secmgr)
      idme2stype = secmgr.idsec2stype(secmgr.idme2sec,:);
    end
    function idme2var = get.idme2var(secmgr)
      idme2var = secmgr.idsec2var(secmgr.idme2sec,:);
    end
    
    % 断面->タイプ別ID変換
    function idsec2wfs = get.idsec2wfs(secmgr)
      idsec2wfs = secmgr.idMapper_.mapSectionToWfs();
    end
    function idsec2hss = get.idsec2hss(secmgr)
      idsec2hss = secmgr.idMapper_.mapSectionToHss();
    end
    function idsec2rcrs = get.idsec2rcrs(secmgr)
      idsec2rcrs = secmgr.idMapper_.mapSectionToRcrs();
    end
    function idsec2brbs = get.idsec2brbs(secmgr)
      idsec2brbs = secmgr.idMapper_.mapSectionToBrbs();
    end
    
    % タイプ別ID->断面逆変換
    function idwfs2sec = get.idwfs2sec(secmgr)
      idwfs2sec = secmgr.idMapper_.mapWfsToSection();
    end
    function idhss2sec = get.idhss2sec(secmgr)
      idhss2sec = secmgr.idMapper_.mapHssToSection();
    end
    function idbrbs2sec = get.idbrbs2sec(secmgr)
      idbrbs2sec = secmgr.idMapper_.mapBrbsToSection();
    end
    function idrcrs2sec = get.idrcrs2sec(secmgr)
      idrcrs2sec = secmgr.idMapper_.mapRcrsToSection();
    end
    
    %% 断面->代表断面変換
    function idhss2rephss = get.idhss2rephss(secmgr)
      idhss2rephss = secmgr.idMapper_.mapHssToRepresentative();
    end
    function idwfs2repwfs = get.idwfs2repwfs(secmgr)
      idwfs2repwfs = secmgr.idMapper_.mapWfsToRepresentative();
    end
    function idrcrs2reprcrs = get.idrcrs2reprcrs(secmgr)
      idrcrs2reprcrs = secmgr.idMapper_.mapRcrsToRepresentative();
    end
    function idbrbs2repbrbs = get.idbrbs2repbrbs(secmgr)
      idbrbs2repbrbs = secmgr.idMapper_.mapBrbsToRepresentative();
    end
    %----------------------------------------------------------------------
    function idsrep2var = get.idsrep2var(secmgr)
      idsrep2var = secmgr.idMapper_.idsrep2var;
    end
    function idsrep2stype = get.idsrep2stype(secmgr)
      idsrep2stype = secmgr.idMapper_.idsrep2stype;
    end
    %---
    function idrephss2sec = get.idrephss2sec(secmgr)
      idrephss2sec = secmgr.idMapper_.idrephss2sec;
    end
    function idrephss2var = get.idrephss2var(secmgr)
      idrephss2var = secmgr.idMapper_.idrephss2var;
    end
    function idrephss2hss = get.idrephss2hss(secmgr)
      idrephss2hss = secmgr.idMapper_.idrephss2hss;
    end
    %---
    function idrepwfs2sec = get.idrepwfs2sec(secmgr)
      idrepwfs2sec = secmgr.idMapper_.idrepwfs2sec;
    end
    function idrepwfs2var = get.idrepwfs2var(secmgr)
      idrepwfs2var = secmgr.idMapper_.idrepwfs2var;
    end
    function idrepwfs2wfs = get.idrepwfs2wfs(secmgr)
      idrepwfs2wfs = secmgr.idMapper_.idrepwfs2wfs;
    end
    %---
    function idreprcrs2sec = get.idreprcrs2sec(secmgr)
      idreprcrs2sec = secmgr.idMapper_.idreprcrs2sec;
    end
    function idreprcrs2rcrs = get.idreprcrs2rcrs(secmgr)
      idreprcrs2rcrs = secmgr.idMapper_.idreprcrs2rcrs;
    end
    %---
    function idrepbrbs2sec = get.idrepbrbs2sec(secmgr)
      idrepbrbs2sec = secmgr.idMapper_.idrepbrbs2sec;
    end
    function idrepbrbs2var = get.idrepbrbs2var(secmgr)
      idrepbrbs2var = secmgr.idMapper_.idrepbrbs2var;
    end
    function idrepbrbs2brbs = get.idrepbrbs2brbs(secmgr)
      idrepbrbs2brbs = secmgr.idMapper_.idrepbrbs2brbs;
    end
    
    %% PropertyCalculatorへの委譲（材料関連）
    % 材料プロパティ取得
    function mat = get.material(secmgr)
      % materialをPropertyCalculatorから取得
      mat = secmgr.propertyCalculator_.material;
    end
    
    % 断面リストの材料情報取得
    function idmat = getIdSecList2Material(secmgr, idslist)
      idmat = secmgr.propertyCalculator ...
        .extractSectionListMaterialId(idslist);
    end
    function F = getIdSecList2F(secmgr, idslist)
      F = secmgr.propertyCalculator.extractSectionListMaterialF(idslist);
    end
    
    function isSN = getIdSecList2isSN(secmgr, idslist)
      isSN = secmgr.propertyCalculator.extractSectionListIsSN(idslist);
    end

    function grade = getIdSecList2Grade(secmgr, idslist)
      grade = secmgr.propertyCalculator.extractSectionListGrade(idslist);
    end
    
    % コスト係数・応力係数取得
    function sectionCostFactor = getSectionCostFactor( ...
        secmgr, idsec2slist)
    %getSectionCostFactor - 断面コスト係数を取得
    %   sectionCostFactor = getSectionCostFactor( ...
    %     secmgr, idsec2slist)
    %   は、断面リストIDと断面IDのペアから各断面のコスト係数を取得します。
    %
    %   参考:
    %     SectionPropertyCalculator.getSectionCostFactor

      sectionCostFactor = ...
        secmgr.propertyCalculator.getSectionCostFactor( ...
        idsec2slist);
    end

    function memberCostFactor = getMemberCostFactor( ...
        secmgr, idsec2slist)
    %getMemberCostFactor - 部材コスト係数を取得
    %   memberCostFactor = getMemberCostFactor( ...
    %     secmgr, idsec2slist)
    %   は、断面リストIDと断面IDのペアから各部材のコスト係数を取得します。
    %
    %   参考:
    %     SectionPropertyCalculator.getMemberCostFactor

      memberCostFactor = ...
        secmgr.propertyCalculator.getMemberCostFactor( ...
        idsec2slist);
    end

    function memberCostConstant = getMemberCostConstant( ...
        secmgr, idsec2slist)
    %getMemberCostConstant 部材コスト定数を取得
    %   memberCostConstant = getMemberCostConstant(secmgr, idsec2slist)
    %   は、断面リストIDと断面IDのペアから各部材のコスト定数を取得します。
    %
    %   参考:
    %     SectionPropertyCalculator.getMemberCostConstant

      memberCostConstant = ...
        secmgr.propertyCalculator.getMemberCostConstant( ...
        idsec2slist);
    end

    function sectionStressFactor = getSectionStressFactor( ...
        secmgr, idsec2slist)
    %getSectionStressFactor 断面応力係数を取得
    %   sectionStressFactor = getSectionStressFactor(secmgr, idsec2slist)
    %   は、断面リストIDと断面IDのペアから各断面の応力係数を取得します。
    %
    %   参考:
    %     SectionPropertyCalculator.getSectionStressFactor
      
      sectionStressFactor = ...
        secmgr.propertyCalculator.getSectionStressFactor( ...
        idsec2slist);
    end
    
    % 断面・部材の材料情報抽出
    function F = extractSectionMaterialF(secmgr, secdim, matF)
      F = secmgr.propertyCalculator.extractSectionMaterialF(secdim, matF);
    end
    function idMemberToMaterial = getIdMemberToMaterial( ...
        secmgr, idsec2slist)
      idMemberToMaterial = secmgr.propertyCalculator ...
        .extractMemberMaterialId(idsec2slist);
    end

    function idMemberToSubList = getIdMemberToSubList(secmgr, idsec2slist)
      % 部材→サブリストマッピングを取得（動的計算）
      % idsec2slistは動的に変化するため、IdMapperへ委譲して計算
      idMemberToSubList = ...
        secmgr.idMapper.mapIdMemberToSubList(idsec2slist);
    end

    function F = extractMemberMaterialF(secmgr, secdim, matF)
      F = secmgr.propertyCalculator.extractMemberMaterialF(secdim, matF);
    end

    function grade = extractMemberMaterialGrade(secmgr, secdim, matGrade)
      grade = secmgr.propertyCalculator ...
        .extractMemberMaterialGrade(secdim, matGrade);
    end
    
    %% 断面リストID変換（deprecatedと新実装混在）
    function idwfs2slist = get.idwfs2slist(secmgr)
      idwfs2slist = secmgr.idMapper_.idwfs2slist;
    end
    function idhss2slist = get.idhss2slist(secmgr)
      idhss2slist = secmgr.idMapper_.idhss2slist;
    end
    function idbrbs2slist = get.idbrbs2slist(secmgr)
      idbrbs2slist = secmgr.idMapper_.idbrbs2slist;
    end
    
    %% 近傍探索系メソッド（委譲のみ）
    function [xlist, idvlist, sdlist] = generateNeighborhoodSet( ...
        secmgr, xvar, isvar, options, initial_guess, com)
    %generateNeighborhoodSet 近傍断面集合の生成
    %   [xlist, idvlist, sdlist] = generateNeighborhoodSet( ...
    %     secmgr, xvar, isvar, options) は、指定された変数値から
    %   近傍断面の集合を生成します。
    %
    %   入力引数:
    %     xvar    - 現在の変数値 [1×nxvar]
    %     isvar   - 変数の有効フラグ [nxvar×1] 論理値配列
    %     options - オプション構造体
    %
    %   参考:
    %     SectionNeighborSearcher.generateNeighborhoodSet
      
      if nargin < 5
        initial_guess = [];
      end
      if nargin < 6
        com = [];
      end
      [xlist, idvlist, sdlist] = secmgr.neighborSearcher ...
        .generateNeighborhoodSet(xvar, isvar, options, ...
        initial_guess, com);
    end
    
    function [secdim, id] = findNearestSection(secmgr, xvar, ...
        options, initial_guess)
    %findNearestSection - 設計変数から最近傍の規格断面を選択
    %   [secdim, id] = findNearestSection(secmgr, xvar, options,
    %     initial_guess) は、設計変数から最近傍の規格断面を選択します。
    %
    %   入力引数:
    %     secmgr       - SectionManagerインスタンス
    %     xvar         - 設計変数ベクトル [1×nxvar]
    %     options      - 共通オプション
    %     initial_guess - 直前の写像結果。省略時は既存処理
    %
    %   出力引数:
    %     secdim - 断面寸法配列 [nsec×7]
    %     id     - 断面リストIDと断面IDを保持する構造体
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestSection
      
      if nargin < 4
        initial_guess = [];
      end
      [secdim, id] = secmgr.neighborSearcher.findNearestSection( ...
        xvar, options, initial_guess);
    end
    
    function [xvar, secdim, mapping_info] = ...
        findNearestSectionAndXvar(secmgr, xvar0, options, initial_guess)
    %findNearestSectionAndXvar - 最近傍断面と変数値を一体で求める
    %   [xvar, secdim, mapping_info] = findNearestSectionAndXvar(
    %     secmgr, xvar0, options, initial_guess) は、最近傍断面を選択し、
    %   影響する設計変数だけを断面値へ補正します。
    %
    %   入力引数:
    %     secmgr - SectionManagerインスタンス
    %     xvar0 - 写像前の設計変数ベクトル [1×nxvar]
    %     options - 共通オプション
    %     initial_guess - 直前の写像結果。省略可能
    %
    %   出力引数:
    %     xvar - 写像後の設計変数ベクトル [1×nxvar]
    %     secdim - 写像後の断面寸法配列 [nsec×7]
    %     mapping_info - 再利用行数、再計算変数数、補正変数数
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestSectionAndXvar

      if nargin < 4
        initial_guess = [];
      end
      if nargout >= 3
        [xvar, secdim, mapping_info] = secmgr.neighborSearcher ...
          .findNearestSectionAndXvar(xvar0, options, initial_guess);
      else
        [xvar, secdim] = secmgr.neighborSearcher ...
          .findNearestSectionAndXvar(xvar0, options, initial_guess);
      end
    end

    function [wfsec, repwfs, id] = findNearestSectionWfs( ...
        secmgr, xvar, idslist, options)
    %findNearestSectionWfs WFS断面の最近傍選択
    %   [wfsec, repwfs, id] = findNearestSectionWfs(secmgr, xvar,
    %     idslist, options) は、WFS断面の最近傍を選択します。
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestSectionWfs
      
      [wfsec, repwfs, id] = ...
        secmgr.neighborSearcher.findNearestSectionWfs(...
          xvar, idslist, options);
    end
    
    function [hssec, rephss, id] = findNearestSectionHss( ...
        secmgr, xvar, idslist, options)
    %findNearestSectionHss HSS断面の最近傍選択
    %   [hssec, rephss, id] = findNearestSectionHss(secmgr, xvar,
    %     idslist, options) は、HSS断面の最近傍を選択します。
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestSectionHss
      
      [hssec, rephss, id] = ...
        secmgr.neighborSearcher.findNearestSectionHss(...
          xvar, idslist, options);
    end
    
    function [brbsec, repbrbs, id] = findNearestSectionBrb( ...
        secmgr, xvar, idslist, options)
    %findNearestSectionBrb BRB断面の最近傍選択
    %   [brbsec, repbrbs, id] = findNearestSectionBrb(secmgr, xvar,
    %     idslist, options) は、BRB断面の最近傍を選択します。
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestSectionBrb
      
      [brbsec, repbrbs, id] = ...
        secmgr.neighborSearcher.findNearestSectionBrb(...
          xvar, idslist, options);
    end
    
    function [xlist, sdlist] = findNearestXList( ...
        secmgr, xlist, options, initial_guess, com)
    %findNearestXList 変数リストから最近傍断面を選択
    %   [xlist, sdlist] = findNearestXList(secmgr, xlist, options) は、
    %   変数値リストの各要素について最近傍の規格断面を選択します。
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestXList
      
      if nargin < 4
        initial_guess = [];
      end
      if nargin < 5
        com = [];
      end
      [xlist, sdlist] = secmgr.neighborSearcher.findNearestXList( ...
        xlist, options, initial_guess, com);
    end
    
    function [xvar, mapping_info] = findNearestXvar( ...
        secmgr, secdim, options, initial_guess)
    %findNearestXvar - 断面寸法から変数値を抽出
    %
    %   [xvar, mapping_info] = findNearestXvar(secmgr, secdim, options,
    %   initial_guess) は、断面寸法データから対応する変数値を抽出する。
    %   initial_guess指定時は変更代表断面だけを再計算する。
    %   initial_guessを省略した場合は、既存の全逆写像を実行する。
    %
    %   入力引数:
    %     secdim - 断面寸法データ [nsec×7]
    %     options - 共通オプション
    %     initial_guess - 直前の逆写像結果（.x、.secdim）。省略可能
    %
    %   出力引数:
    %     xvar - 変数値ベクトル [1×nxvar]
    %     mapping_info - 再利用した断面行数と設計変数数
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestXvar
      
      if nargin < 4
        initial_guess = [];
      end
      if nargout >= 2
        [xvar, mapping_info] = secmgr.neighborSearcher ...
          .findNearestXvar(secdim, options, initial_guess);
      else
        xvar = secmgr.neighborSearcher.findNearestXvar( ...
          secdim, options, initial_guess);
      end
    end
    
    function xvar = findNearestXvarofWfs(secmgr, repwfs, xvar0, options)
    %findNearestXvarofWfs WFS断面の最近傍変数値を検索
    %   xvar = findNearestXvarofWfs(secmgr, repwfs, xvar0, options) は、
    %   WFS断面の代表断面から最近傍の変数値を検索します。
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestXvarofWfs
      
      % SectionNeighborSearcherに委譲
      xvar = secmgr.neighborSearcher.findNearestXvarofWfs(...
        repwfs, xvar0, options);
    end
    
    function xvar = findNearestXvarofHss(secmgr, rephss, xvar0, options)
    %findNearestXvarofHss HSS断面の最近傍変数値を検索
    %   xvar = findNearestXvarofHss(secmgr, rephss, xvar0, options) は、
    %   HSS断面の代表断面から最近傍の変数値を検索します。
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestXvarofHss
      
      % SectionNeighborSearcherに委譲
      xvar = secmgr.neighborSearcher.findNearestXvarofHss(...
        rephss, xvar0, options);
    end
    
    function xvar = findNearestXvarofBrb(secmgr, repbrbs, xvar0, options)
    %findNearestXvarofBrb BRB断面の最近傍変数値を検索
    %   xvar = findNearestXvarofBrb(secmgr, repbrbs, xvar0, options) は、
    %   BRB断面の代表断面から最近傍の変数値を検索します。
    %
    %   参考:
    %     SectionNeighborSearcher.findNearestXvarofBrb
      
      % SectionNeighborSearcherに委譲
      xvar = secmgr.neighborSearcher.findNearestXvarofBrb(...
        repbrbs, xvar0, options);
    end
    
    %% 近傍探索系メソッド（委譲のみ）
    function [xlist, xup, xdw, idvlist] = enumerateNeighborH( ...
        secmgr, xvar, idvar, options, delta)
    %enumerateNeighborH 梁せいHの近傍断面を列挙
    %   [xlist, xup, xdw, idvlist] = enumerateNeighborH(secmgr, xvar, 
    %     idvar, options, delta) は、梁せいHの近傍断面を列挙します。
    %
    %   入力引数:
    %     xvar    - 現在の変数値 [1×nxvar]
    %     idvar   - 対象変数ID (スカラー)
    %     options - オプション構造体
    %     delta   - 探索範囲 (mm、省略可能、既定値: 150)
    %
    %   参考:
    %     SectionNeighborSearcher.enumerateNeighborH
      
      if nargin == 4
        delta = 150;
      end
      
      % neighborSearcherに委譲
      [xlist, xup, xdw, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborH(...
          xvar, idvar, options, delta);
    end
    
    function [xlist, xup, xdw, idvlist] = enumerateNeighborB( ...
        secmgr, xvar, idvar, options)
    %enumerateNeighborB フランジ幅Bの近傍断面を列挙
    %   [xlist, xup, xdw, idvlist] = enumerateNeighborB(secmgr, xvar,
    %     idvar, options) は、フランジ幅Bの近傍断面を列挙します。
    %
    %   参考:
    %     SectionNeighborSearcher.enumerateNeighborB
      
      % neighborSearcherに委譲
      [xlist, xup, xdw, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborB(...
          xvar, idvar, options);
    end
    
    function [xlist, xup, xdw, idvlist] = enumerateNeighborD( ...
        secmgr, xvar, idvar, options)
    %enumerateNeighborD 径Dの近傍断面を列挙
    %   [xlist, xup, xdw, idvlist] = enumerateNeighborD(secmgr, xvar,
    %     idvar, options) は、径Dの近傍断面を列挙します。
    %
    %   参考:
    %     SectionNeighborSearcher.enumerateNeighborD
      
      % neighborSearcherに委譲
      [xlist, xup, xdw, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborD(...
          xvar, idvar, options);
    end
    
    function [xlist, xup, xdw, idvartarget, idvlist] = ...
      enumerateNeighborT(secmgr, xvar, idvar, options)
    %enumerateNeighborT 厚さtの近傍断面を列挙
    %   [xlist, xup, xdw, idvartarget, idvlist] = enumerateNeighborT(
    %     secmgr, xvar, idvar, options) は、厚さtの近傍断面を列挙します。
    %
    %   参考:
    %     SectionNeighborSearcher.enumerateNeighborT
      
      % neighborSearcherに委譲
      [xlist, xup, xdw, idvartarget, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborT(...
          xvar, idvar, options);
    end
    
    function [xlist, xup, xdw, idvartarget, idvlist] = ...
      enumerateNeighborTw(secmgr, xvar, idvar, options)
    %enumerateNeighborTw ウェブ厚twの近傍断面を列挙
    %   [xlist, xup, xdw, idvartarget, idvlist] = enumerateNeighborTw(
    %     secmgr, xvar, idvar, options) は、
    %     ウェブ厚twの近傍断面を列挙します。
    %
    %   参考:
    %     SectionNeighborSearcher.enumerateNeighborTw
      
      % neighborSearcherに委譲
      [xlist, xup, xdw, idvartarget, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborTw(...
          xvar, idvar, options);
    end
    
    function [xlist, xup, xdw, idvartarget, idvlist] = ...
      enumerateNeighborTf(secmgr, xvar, idvar, options)
    %enumerateNeighborTf フランジ厚tfの近傍断面を列挙
    %   [xlist, xup, xdw, idvartarget, idvlist] = enumerateNeighborTf(
    %     secmgr, xvar, idvar, options) は、
    %     フランジ厚tfの近傍断面を列挙します。
    %
    %   参考:
    %     SectionNeighborSearcher.enumerateNeighborTf
      
      % neighborSearcherに委譲
      [xlist, xup, xdw, idvartarget, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborTf(...
          xvar, idvar, options);
    end
    
    %% データアクセス系メソッド（委譲のみ）
    function dimension = getDimension(secmgr, idList, idphase)
    %getDimension 断面寸法を取得
    %   dimension = getDimension(secmgr, idList, idphase) は、
    %   指定された断面IDリストの寸法を取得します。
    %
    %   入力引数:
    %     idList  - 断面IDリスト
    %     idphase - フェーズID（省略可能、既定値: secmgr.idphase）
    %
    %   参考:
    %     SectionStandardAccessor.getSectionDimension
      
      % StandardAccessorに委譲
      if nargin == 2
        dimension = secmgr.standardAccessor.getSectionDimension(idList);
      else
        dimension = secmgr.standardAccessor ...
          .getSectionDimension(idList, idphase);
      end
    end
    
    function [stvals, stnum] = getStandardValues(secmgr)
    %getStandardValues 全断面リストの規格値セットを取得
    %   [stvals, stnum] = getStandardValues(secmgr) は、
    %   GA最適化で使用する全断面の規格値を統合して返します。
    %
    %   出力引数:
    %     stvals - 規格値配列 [nxvar×max(stnum)] NaN埋め
    %     stnum - 各変数の規格値数 [nxvar×1]
    %
    %   例:
    %     [vals, nums] = secmgr.getStandardValues();
    %
    %   参考:
    %     SectionStandardAccessor.getStandardValues
      
      % StandardAccessorに委譲
      [stvals, stnum] = secmgr.standardAccessor.getStandardValues();
    end
    
    function record = getListRecord(secmgr, secdim)
    %getListRecord 断面テーブルレコードを取得
    %   record = getListRecord(secmgr, secdim) は、
    %   secdim の末尾2列（断面リストID, 断面ID）から
    %   対応するテーブルレコードを取得します。
    %
    %   入力引数:
    %     secdim - 断面寸法配列 [n×ncol]
    %
    %   出力引数:
    %     record - テーブルレコード (table型) [n×列数]
    %
    %   参考:
    %     SectionStandardAccessor.getListRecord

      % StandardAccessorに委譲
      record = secmgr.standardAccessor.getListRecord(secdim);
    end
    
    function initValidSectionFlagCell(secmgr)
    %initValidSectionFlagCell 有効断面フラグセルの初期化
    %   initValidSectionFlagCell(secmgr) は、有効断面フラグセルの初期化を
    %   SectionConstraintValidatorに委譲します。
    %
    %   例:
    %     secmgr.initValidSectionFlagCell();
    %
    %   参考:
    %     SectionConstraintValidator.initValidSectionFlagCell
      
      % SectionConstraintValidatorに委譲
      secmgr.constraintValidator.initValidSectionFlagCell();
    end
    
    %% 制約チェック系メソッド（委譲のみ）
    function isvalid = getValidSectionOfSlist(secmgr, idslist, idphase)
    %getValidSectionOfSlist 有効断面リストを取得
    %   isvalid = getValidSectionOfSlist(secmgr, idslist, idphase) は、
    %   指定された断面リストの有効フラグを取得します。
    %
    %   入力引数:
    %     idslist - 断面リストID
    %     idphase - フェーズID（省略可能、既定値: secmgr.idphase）
    %
    %   参考:
    %     SectionConstraintValidator.extractValidSectionFlags
      
      if nargin == 2
        isvalid = secmgr.constraintValidator ...
          .extractValidSectionFlags(idslist);
      else
        isvalid = secmgr.constraintValidator ...
          .extractValidSectionFlags(idslist, idphase);
      end
    end
    
    function limit_jbs_section(secmgr, isjbs, ...
        nominal_girder, section_girder, ...
        section_column, options, apply_filter)
    %limit_jbs_section - 保有耐力接合(JBS)制限チェック
    %
    %   limit_jbs_section(secmgr, isjbs,
    %   nominal_girder, section_girder,
    %   section_column, options) は、保有耐力接合の
    %   制限チェックを実行します。
    %
    %   入力引数:
    %     isjbs          - JBS判定対象フラグ [nng×2]
    %     nominal_girder - 名目梁テーブル
    %     section_girder - 梁断面構造体
    %     section_column - 柱断面構造体
    %     options        - オプション構造体
    %     apply_filter   - 候補リスト更新フラグ（省略時true）
    %
    %   参考:
    %     SectionConstraintValidator.limitJbsSection

      if nargin < 7
        apply_filter = true;
      end

      % constraintValidatorへ委譲
      secmgr.constraintValidator.limitJbsSection(...
        isjbs, nominal_girder, section_girder, ...
        section_column, secmgr, options, apply_filter);
    end

    function limit_slr_section(secmgr, member, nominal, lm, options)
    %limit_slr_section 細長比制限チェック

      % constraintValidatorへ委譲
      secmgr.constraintValidator.limitSlrSection(member, ...
        nominal, lm, secmgr, options);
    end
    
    function limit_wtratio_section(secmgr, section, options)
    %limit_wtratio_section 幅厚比制限チェック
    %   limit_wtratio_section(secmgr, section, options) は、
    %   幅厚比の制限チェックを実行します。
    %
    %   入力引数:
    %     section - 断面情報構造体
    %     options - オプション構造体
    %
    %   参考:
    %     SectionConstraintValidator.limitWtRatioSection

      % constraintValidatorへ委譲
      secmgr.constraintValidator.limitWtRatioSection( ...
        section, options, secmgr);
    end

    %% ユーティリティメソッド
    function x = generateRandomXvar(secmgr, seed, lm, options)
    %generateRandomXvar ランダム初期解を生成
    %   x = generateRandomXvar(secmgr, seed, lm, options) は、
    %   最適化用のランダム初期解を生成します。
    %
    %   入力引数:
    %     seed - 乱数シード (省略時はshuffle)
    %     lm - 部材長さ配列 [nme×1] (省略可能)
    %     options - オプション構造体 (省略可能)
    %       .do_limit_initial_girder_height - 梁せい制限フラグ
    %
    %   出力引数:
    %     x - 設計変数ベクトル [1×nxvar]

      % generate_random_initial_solution関数を呼び出し
      x = generate_random_initial_solution(secmgr.standardAccessor_, ...
        secmgr.idMapper_, secmgr.secList, seed, lm, options);
    end
  end
end
