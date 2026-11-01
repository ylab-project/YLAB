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
    isValidSectionOfSlist_  % 有効断面リスト
    column_base_list        % 柱脚リスト

    %% 断面数関連
    nxvar
    nsec
    nsrep, nrephss, nrepwfs, nreprcrs, nrepbrbs
    nlist

    %% 上下限
    lb, ub

    %% ID変換マッピング
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
      %findUpDownWfsThick - WFS断面の板厚増減を探索する
      %
      %   [upsec, dwsec] = findUpDownWfsThick(secwfs, twortf, seclist, ...
      %     options)
      %
      %   入力引数:
      %     secwfs - 対象WFS断面 [H, B, tw, tf]
      %     twortf - 対象板厚 ('tw'または'tf')
      %     seclist - 断面リスト [nlist×4]
      %     options - オプション構造体（tolHgap, tolBgap含む）
      %
      %   出力引数:
      %     upsec - 板厚を増やした断面 [H, B, tw, tf]（存在しない場合は空）
      %     dwsec - 板厚を減らした断面 [H, B, tw, tf]（存在しない場合は空）
      [upsec, dwsec] = SectionNeighborSearcher.findUpDownWfsThick(...
        secwfs, twortf, seclist, options);
    end

    function [upsec, dwsec] = findUpDownHssThick(sechss, seclist, options)
      %findUpDownHssThick - HSS断面の板厚増減を探索する
      %
      %   [upsec, dwsec] = findUpDownHssThick(sechss, seclist, options)
      %
      %   入力引数:
      %     sechss - 対象HSS断面 [D, t]
      %     seclist - 断面リスト [nlist×6]
      %     options - オプション構造体（tolDgap含む）
      %
      %   出力引数:
      %     upsec - 板厚を増やした断面 [D, t]（存在しない場合は空）
      %     dwsec - 板厚を減らした断面 [D, t]（存在しない場合は空）
      [upsec, dwsec] = SectionNeighborSearcher.findUpDownHssThick(...
        sechss, seclist, options);
    end

    function idsec2slist = getSectionListMapping(secdim)
      %getSectionListMapping - 断面リストID/断面IDマッピングを取得（委譲）
      %
      %   idsec2slist = getSectionListMapping(secdim)
      %
      %   入力引数:
      %     secdim - 写像済みの全断面寸法 [nsec×7] (mm)
      %
      %   出力引数:
      %     idsec2slist - 断面ごとの断面リストIDと候補行番号 [nsec×2]
      idsec2slist = SectionNeighborSearcher.getSectionListMapping(secdim);
    end
  end
  methods
    %% idphaseのgetter/setter（standardAccessorに委譲）
    function val = get.idphase(secmgr)
      %get.idphase - 探索フェーズ番号を取得する
      %
      %   val = secmgr.idphase
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 探索フェーズ番号
      val = secmgr.standardAccessor_.idPhase;
    end

    function set.idphase(secmgr, val)
      %set.idphase - フェーズと検索配列・上下限を同期する
      %
      %   secmgr.idphase = val は、規格値のフェーズを切り替え、有効断面
      %   フラグと上下限を更新する。同じフェーズの再指定でも更新する。
      %
      %   入力引数:
      %     secmgr - SectionManagerオブジェクト
      %     val    - フェーズ番号
      %
      %   出力引数:
      %     なし

      secmgr.standardAccessor_.idPhase = val;
      secmgr.constraintValidator_.updateValidSectionFlagCell(val);
      secmgr.constraintValidator_.updateGlobalBounds();

      return
    end

    %% neighborSearcherから取得するプロパティのgetter
    function val = get.dimension(secmgr)
      %get.dimension - 候補断面の寸法配列を取得する
      %
      %   val = secmgr.dimension
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 候補断面の寸法配列
      if ~isempty(secmgr.neighborSearcher_)
        val = secmgr.neighborSearcher_.dimension;
      else
        val = [];
      end
    end

    function val = get.idHgap2var(secmgr)
      %get.idHgap2var - 梁せい差の対象変数IDを取得する
      %
      %   val = secmgr.idHgap2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 梁せい差の対象変数ID
      if ~isempty(secmgr.neighborSearcher_)
        val = secmgr.neighborSearcher_.idHgap2var;
      else
        val = [];
      end
    end

    function val = get.idHgap2sec(secmgr)
      %get.idHgap2sec - 梁せい差の対象断面IDを取得する
      %
      %   val = secmgr.idHgap2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 梁せい差の対象断面ID
      if ~isempty(secmgr.neighborSearcher_)
        val = secmgr.neighborSearcher_.idHgap2sec;
      else
        val = [];
      end
    end

    %% ConstraintValidatorから取得するプロパティのgetter
    function isValidSectionOfSlist = get.isValidSectionOfSlist_(secmgr)
      %get.isValidSectionOfSlist_ - 有効断面フラグを取得する
      %
      %   isValidSectionOfSlist = secmgr.isValidSectionOfSlist_
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     isValidSectionOfSlist - 断面リスト別の有効断面フラグのcell配列
      if ~isempty(secmgr.constraintValidator_)
        isValidSectionOfSlist = ...
          secmgr.constraintValidator_.validSectionFlagCell;
      else
        % 初期化されていない場合は空のcell配列を返す
        isValidSectionOfSlist = {};
      end
    end

    function set.isValidSectionOfSlist_(secmgr, value)
      %set.isValidSectionOfSlist_ - 有効断面フラグを設定する
      %
      %   secmgr.isValidSectionOfSlist_ = value
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     value - 断面リスト別の有効断面フラグのcell配列
      %
      %   出力引数:
      %     なし
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
      %get.nxvar - 変数総数を取得する
      %
      %   nx = secmgr.nxvar
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nx - 変数総数
      if ~isempty(secmgr.idMapper_)
        nx = secmgr.idMapper_.nxvar;
      else
        nx = 0;
      end
    end

    function val = get.idvar2vtype(secmgr)
      %get.idvar2vtype - 変数タイプマッピングを取得する
      %
      %   val = secmgr.idvar2vtype
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 変数タイプマッピング [nxvar×1]
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idvar2vtype;
      else
        val = [];
      end
    end

    function val = get.idSectionList(secmgr)
      %get.idSectionList - 断面→断面リストIDを取得する
      %
      %   val = secmgr.idSectionList
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 断面→断面リストID [nsec×1]（静的）
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idSectionList;
      else
        val = [];
      end
    end

    function val = get.idsec2stype(secmgr)
      %get.idsec2stype - 断面→断面タイプマッピングを取得する
      %
      %   val = secmgr.idsec2stype
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 断面→断面タイプマッピング [nsec×1]
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idsec2stype;
      else
        val = [];
      end
    end

    function val = get.idsec2srep(secmgr)
      %get.idsec2srep - 断面→代表断面マッピングを取得する
      %
      %   val = secmgr.idsec2srep
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 断面→代表断面マッピング [nsec×1]
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idsec2srep;
      else
        val = [];
      end
    end

    function val = get.idH2var(secmgr)
      %get.idH2var - H変数ID配列を取得する
      %
      %   val = secmgr.idH2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - H変数ID配列（WFS断面）
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idH2var;
      else
        val = [];
      end
    end

    function val = get.idB2var(secmgr)
      %get.idB2var - B変数ID配列を取得する
      %
      %   val = secmgr.idB2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - B変数ID配列（WFS断面）
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idB2var;
      else
        val = [];
      end
    end

    function val = get.idtw2var(secmgr)
      %get.idtw2var - tw変数ID配列を取得する
      %
      %   val = secmgr.idtw2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - tw変数ID配列（WFS断面）
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idtw2var;
      else
        val = [];
      end
    end

    function val = get.idtf2var(secmgr)
      %get.idtf2var - tf変数ID配列を取得する
      %
      %   val = secmgr.idtf2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - tf変数ID配列（WFS断面）
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idtf2var;
      else
        val = [];
      end
    end

    function val = get.idD2var(secmgr)
      %get.idD2var - D変数ID配列を取得する
      %
      %   val = secmgr.idD2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - D変数ID配列（HSS断面）
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idD2var;
      else
        val = [];
      end
    end

    function val = get.idt2var(secmgr)
      %get.idt2var - t変数ID配列を取得する
      %
      %   val = secmgr.idt2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - t変数ID配列（HSS断面）
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idt2var;
      else
        val = [];
      end
    end

    function val = get.idBrb1_var(secmgr)
      %get.idBrb1_var - BRB V1変数ID配列を取得する
      %
      %   val = secmgr.idBrb1_var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - BRB V1変数ID配列
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idBrb1_var;
      else
        val = [];
      end
    end

    function val = get.idBrb2_var(secmgr)
      %get.idBrb2_var - BRB V2変数ID配列を取得する
      %
      %   val = secmgr.idBrb2_var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - BRB V2変数ID配列
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idBrb2_var;
      else
        val = [];
      end
    end

    function val = get.idsec2var(secmgr)
      %get.idsec2var - 断面→変数を取得する
      %
      %   val = secmgr.idsec2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 断面→変数 [nsec×ndim]
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idsec2var;
      else
        val = [];
      end
    end

    function val = get.idsrep2sec(secmgr)
      %get.idsrep2sec - 代表断面→断面を取得する
      %
      %   val = secmgr.idsrep2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 代表断面→断面 [nsrep×1]
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idsrep2sec;
      else
        val = [];
      end
    end

    function val = get.idvar2srep(secmgr)
      %get.idvar2srep - 変数→代表断面を取得する
      %
      %   val = secmgr.idvar2srep
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 変数→代表断面 cell配列
      if ~isempty(secmgr.idMapper_)
        val = secmgr.idMapper_.idvar2srep;
      else
        val = [];
      end
    end

    function isVarofSlist = get.isVarofSlist(secmgr)
      %get.isVarofSlist - 変数-断面リストマッピングを取得する
      %
      %   isVarofSlist = secmgr.isVarofSlist
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     isVarofSlist - 変数-断面リストマッピング [nxvar×nlist]
      if ~isempty(secmgr.idMapper_)
        isVarofSlist = secmgr.idMapper_.isVarofSlist;
      else
        isVarofSlist = [];
      end
    end

    function val = get.column_base_list(secmgr)
      %get.column_base_list - 柱脚リストを取得する
      %
      %   val = secmgr.column_base_list
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     val - 柱脚リスト
      if ~isempty(secmgr.constraintValidator_)
        val = secmgr.constraintValidator_.columnBaseList;
      else
        val = [];
      end
    end

    %% 断面数関連のDependentプロパティgetter
    function nsec = get.nsec(secmgr)
      %get.nsec - 総断面数を取得する
      %
      %   nsec = secmgr.nsec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nsec - 総断面数
      nsec = length(secmgr.idsec2stype);
    end
    %---
    function nrepsec = get.nsrep(secmgr)
      %get.nsrep - 代表断面数を取得する
      %
      %   nrepsec = secmgr.nsrep
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nrepsec - 代表断面数
      nrepsec = size(secmgr.idsrep2sec,1);
    end
    function nrephss = get.nrephss(secmgr)
      %get.nrephss - 代表HSS断面数を取得する
      %
      %   nrephss = secmgr.nrephss
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nrephss - 代表HSS断面数
      nrephss = length(secmgr.idrephss2hss);
    end
    function nrepwfs = get.nrepwfs(secmgr)
      %get.nrepwfs - 代表WFS断面数を取得する
      %
      %   nrepwfs = secmgr.nrepwfs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nrepwfs - 代表WFS断面数
      nrepwfs = length(secmgr.idrepwfs2wfs);
    end
    function nreprcrs = get.nreprcrs(secmgr)
      %get.nreprcrs - 代表RCRS断面数を取得する
      %
      %   nreprcrs = secmgr.nreprcrs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nreprcrs - 代表RCRS断面数
      nreprcrs = length(secmgr.idreprcrs2rcrs);
    end
    function nrepbrbs = get.nrepbrbs(secmgr)
      %get.nrepbrbs - 代表BRB断面数を取得する
      %
      %   nrepbrbs = secmgr.nrepbrbs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nrepbrbs - 代表BRB断面数
      nrepbrbs = length(secmgr.idrepbrbs2brbs);
    end

    function nlist = get.nlist(secmgr)
      %get.nlist - 断面リスト数を取得する
      %
      %   nlist = secmgr.nlist
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nlist - 断面リスト数
      nlist = secmgr.secList.nlist;
    end

    %% 内部オブジェクトへのアクセス用getter
    function calculator = get.propertyCalculator(secmgr)
      %get.propertyCalculator - 断面性能の計算オブジェクトを取得する
      %
      %   calculator = secmgr.propertyCalculator
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     calculator - 断面性能の計算オブジェクト
      calculator = secmgr.propertyCalculator_;
    end
    function validator = get.constraintValidator(secmgr)
      %get.constraintValidator - 断面制約の管理オブジェクトを取得する
      %
      %   validator = secmgr.constraintValidator
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     validator - 断面制約の管理オブジェクト
      validator = secmgr.constraintValidator_;
    end

    function accessor = get.standardAccessor(secmgr)
      %get.standardAccessor - 断面規格値の参照オブジェクトを取得する
      %
      %   accessor = secmgr.standardAccessor
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     accessor - 断面規格値の参照オブジェクト
      accessor = secmgr.standardAccessor_;
    end

    function searcher = get.neighborSearcher(secmgr)
      %get.neighborSearcher - 断面近傍の探索オブジェクトを取得する
      %
      %   searcher = secmgr.neighborSearcher
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     searcher - 断面近傍の探索オブジェクト
      searcher = secmgr.neighborSearcher_;
    end

    function mapper = get.idMapper(secmgr)
      %get.idMapper - 断面・変数の対応を管理するオブジェクトを取得する
      %
      %   mapper = secmgr.idMapper
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     mapper - 断面・変数の対応を管理するオブジェクト
      mapper = secmgr.idMapper_;
    end

    %% 断面リスト操作（直接実装）
    function setSectionList(secmgr, secList)
      %setSectionList - 断面リスト管理オブジェクトを設定する
      %
      %   setSectionList(secmgr, secList)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     secList - 断面リスト管理オブジェクト
      %
      %   出力引数:
      %     なし
      secmgr.secList = secList;
    end
    % function setSectionIsValid(secmgr, idslist, isValid)
    %   secmgr.secList.isValid{idslist} = isValid;
    % end
    function sectionType = getSectionType(secmgr, idlist)
      %getSectionType - 断面リストの鉄骨形状を取得する
      %
      %   sectionType = getSectionType(secmgr, idlist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idlist - 断面リストID
      %
      %   出力引数:
      %     sectionType - 断面タイプ (PRM.WFS/HSS/BRB/RCRS)
      sectionType = secmgr.secList.section_type(idlist);
    end
    function nsublist = getNumSectionSubList(secmgr)
      %getNumSectionSubList - サブリスト数を取得する
      %
      %   nsublist = getNumSectionSubList(secmgr)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     nsublist - サブリスト数
      nsublist = secmgr.secList.nsublist;
    end

    %% StandardAccessorへの委譲（規格値取得）
    % 規格値（実寸）取得
    function st = getHst(secmgr, idslist)
      %getHst - H形鋼のせいの規格値を取得する
      %
      %   st = getHst(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     st - H形鋼のせい (mm)
      st = secmgr.standardAccessor.getStandardH(idslist);
    end
    function st = getBst(secmgr, idslist)
      %getBst - H形鋼の幅の規格値を取得する
      %
      %   st = getBst(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     st - H形鋼の幅 (mm)
      st = secmgr.standardAccessor.getStandardB(idslist);
    end
    function st = getTwst(secmgr, idslist)
      %getTwst - H形鋼のウェブ厚の規格値を取得する
      %
      %   st = getTwst(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     st - H形鋼のウェブ厚 (mm)
      st = secmgr.standardAccessor.getStandardTw(idslist);
    end
    function st = getTfst(secmgr, idslist)
      %getTfst - H形鋼のフランジ厚の規格値を取得する
      %
      %   st = getTfst(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     st - H形鋼のフランジ厚 (mm)
      st = secmgr.standardAccessor.getStandardTf(idslist);
    end
    function st = getDst(secmgr, id)
      %getDst - 角形鋼管の径の規格値を取得する
      %
      %   st = getDst(secmgr, id)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     id - 断面リストID
      %
      %   出力引数:
      %     st - 角形鋼管の径 (mm)
      st = secmgr.standardAccessor.getStandardD(id);
    end
    function st = getTst(secmgr, idslist)
      %getTst - 角形鋼管の板厚の規格値を取得する
      %
      %   st = getTst(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     st - 角形鋼管の板厚 (mm)
      st = secmgr.standardAccessor.getStandardT(idslist);
    end
    function st = getBrb1st(secmgr, idslist)
      %getBrb1st - BRBのV1の規格値を取得する
      %
      %   st = getBrb1st(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     st - BRBのV1の規格値
      st = secmgr.standardAccessor.getStandardV1(idslist);
    end
    function st = getBrb2st(secmgr, idslist)
      %getBrb2st - BRBのV2の規格値を取得する
      %
      %   st = getBrb2st(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     st - BRBのV2の規格値
      st = secmgr.standardAccessor.getStandardV2(idslist);
    end

    % 公称値（呼び寸）取得
    function Hnominal = getHnominal(secmgr, idslist)
      %getHnominal - H形鋼のせいの公称値を取得する
      %
      %   Hnominal = getHnominal(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     Hnominal - H形鋼の公称せい (mm)
      Hnominal = secmgr.standardAccessor.getNominalH(idslist);
    end
    function Bnominal = getBnominal(secmgr, idslist)
      %getBnominal - H形鋼の幅の公称値を取得する
      %
      %   Bnominal = getBnominal(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     Bnominal - H形鋼の公称幅 (mm)
      Bnominal = secmgr.standardAccessor.getNominalB(idslist);
    end

    % 変数関連情報取得
    function idslist = getIdSlistofVar(secmgr, idvar)
      %getIdSlistofVar - 変数が使用される断面リストIDを取得
      %
      %   idslist = getIdSlistofVar(secmgr, idvar)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idvar - 変数ID (スカラー整数)
      %
      %   出力引数:
      %     idslist - 断面リストID配列 [1×n]
      idslist = secmgr.idMapper_.getIdSlistofVar(idvar);
    end
    function vset = getNominalValueSetofVar(secmgr, idvar)
      %getNominalValueSetofVar - 変数の公称値セットを取得
      %
      %   vset = getNominalValueSetofVar(secmgr, idvar)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idvar - 変数ID (スカラー整数)
      %
      %   出力引数:
      %     vset - 公称値セット [n×1] 配列
      vset = secmgr.standardAccessor.getNominalValueSetofVar(idvar, ...
        secmgr.idMapper_, secmgr.idsec2var);
    end

    %% ConstraintValidatorへの委譲（制約関連）
    % 上下限値取得（全断面リストの統合値）
    function lb = get.lb(secmgr)
      %get.lb - 現在フェーズの下限値を取得する
      %
      %   lb = secmgr.lb は、フェーズ設定時に確定した下限値を返す。
      %
      %   入力引数:
      %     secmgr - SectionManagerオブジェクト
      %
      %   出力引数:
      %     lb - 設計変数の下限値 [nxvar×1]

      lb = secmgr.constraintValidator_.lb;

      return
    end

    function ub = get.ub(secmgr)
      %get.ub - 現在フェーズの上限値を取得する
      %
      %   ub = secmgr.ub は、フェーズ設定時に確定した上限値を返す。
      %
      %   入力引数:
      %     secmgr - SectionManagerオブジェクト
      %
      %   出力引数:
      %     ub - 設計変数の上限値 [nxvar×1]

      ub = secmgr.constraintValidator_.ub;

      return
    end

    %% ID変換用Dependentプロパティ（計算またはIdMapper委譲）

    % 断面->タイプ別ID変換
    function idsec2wfs = get.idsec2wfs(secmgr)
      %get.idsec2wfs - 断面→WFS断面を取得する
      %
      %   idsec2wfs = secmgr.idsec2wfs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idsec2wfs - 断面→WFS断面 [nsec×1] (0:非WFS)
      idsec2wfs = secmgr.idMapper_.mapSectionToWfs();
    end
    function idsec2hss = get.idsec2hss(secmgr)
      %get.idsec2hss - 断面→HSS断面を取得する
      %
      %   idsec2hss = secmgr.idsec2hss
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idsec2hss - 断面→HSS断面 [nsec×1] (0:非HSS)
      idsec2hss = secmgr.idMapper_.mapSectionToHss();
    end
    function idsec2rcrs = get.idsec2rcrs(secmgr)
      %get.idsec2rcrs - 断面→RCRS断面を取得する
      %
      %   idsec2rcrs = secmgr.idsec2rcrs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idsec2rcrs - 断面→RCRS断面 [nsec×1] (0:非RCRS)
      idsec2rcrs = secmgr.idMapper_.mapSectionToRcrs();
    end
    function idsec2brbs = get.idsec2brbs(secmgr)
      %get.idsec2brbs - 断面→BRB断面を取得する
      %
      %   idsec2brbs = secmgr.idsec2brbs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idsec2brbs - 断面→BRB断面 [nsec×1] (0:非BRB)
      idsec2brbs = secmgr.idMapper_.mapSectionToBrbs();
    end

    % タイプ別ID->断面逆変換
    function idwfs2sec = get.idwfs2sec(secmgr)
      %get.idwfs2sec - WFS断面→断面を取得する
      %
      %   idwfs2sec = secmgr.idwfs2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idwfs2sec - WFS断面→断面 [nwfs×1]
      idwfs2sec = secmgr.idMapper_.mapWfsToSection();
    end
    function idhss2sec = get.idhss2sec(secmgr)
      %get.idhss2sec - HSS断面→断面を取得する
      %
      %   idhss2sec = secmgr.idhss2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idhss2sec - HSS断面→断面 [nhss×1]
      idhss2sec = secmgr.idMapper_.mapHssToSection();
    end
    function idbrbs2sec = get.idbrbs2sec(secmgr)
      %get.idbrbs2sec - BRB断面→断面を取得する
      %
      %   idbrbs2sec = secmgr.idbrbs2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idbrbs2sec - BRB断面→断面 [nbrbs×1]
      idbrbs2sec = secmgr.idMapper_.mapBrbsToSection();
    end
    function idrcrs2sec = get.idrcrs2sec(secmgr)
      %get.idrcrs2sec - RCRS断面→断面を取得する
      %
      %   idrcrs2sec = secmgr.idrcrs2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrcrs2sec - RCRS断面→断面 [nrcrs×1]
      idrcrs2sec = secmgr.idMapper_.mapRcrsToSection();
    end

    %% 断面->代表断面変換
    function idhss2rephss = get.idhss2rephss(secmgr)
      %get.idhss2rephss - HSS断面→代表HSS断面を取得する
      %
      %   idhss2rephss = secmgr.idhss2rephss
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idhss2rephss - HSS断面→代表HSS断面 [nhss×1]
      idhss2rephss = secmgr.idMapper_.mapHssToRepresentative();
    end
    function idwfs2repwfs = get.idwfs2repwfs(secmgr)
      %get.idwfs2repwfs - WFS断面→代表WFS断面を取得する
      %
      %   idwfs2repwfs = secmgr.idwfs2repwfs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idwfs2repwfs - WFS断面→代表WFS断面 [nwfs×1]
      idwfs2repwfs = secmgr.idMapper_.mapWfsToRepresentative();
    end
    function idrcrs2reprcrs = get.idrcrs2reprcrs(secmgr)
      %get.idrcrs2reprcrs - RCRS断面→代表RCRS断面を取得する
      %
      %   idrcrs2reprcrs = secmgr.idrcrs2reprcrs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrcrs2reprcrs - RCRS断面→代表RCRS断面 [nrcrs×1]
      idrcrs2reprcrs = secmgr.idMapper_.mapRcrsToRepresentative();
    end
    function idbrbs2repbrbs = get.idbrbs2repbrbs(secmgr)
      %get.idbrbs2repbrbs - BRB断面→代表BRB断面を取得する
      %
      %   idbrbs2repbrbs = secmgr.idbrbs2repbrbs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idbrbs2repbrbs - BRB断面→代表BRB断面 [nbrbs×1]
      idbrbs2repbrbs = secmgr.idMapper_.mapBrbsToRepresentative();
    end
    %----------------------------------------------------------------------
    function idsrep2var = get.idsrep2var(secmgr)
      %get.idsrep2var - 代表断面→変数を取得する
      %
      %   idsrep2var = secmgr.idsrep2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idsrep2var - 代表断面→変数 [nsrep×ndim]
      idsrep2var = secmgr.idMapper_.idsrep2var;
    end
    function idsrep2stype = get.idsrep2stype(secmgr)
      %get.idsrep2stype - 代表断面→断面タイプを取得する
      %
      %   idsrep2stype = secmgr.idsrep2stype
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idsrep2stype - 代表断面→断面タイプ [nsrep×1]
      idsrep2stype = secmgr.idMapper_.idsrep2stype;
    end
    %---
    function idrephss2sec = get.idrephss2sec(secmgr)
      %get.idrephss2sec - 代表HSS断面→断面を取得する
      %
      %   idrephss2sec = secmgr.idrephss2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrephss2sec - 代表HSS断面→断面 [nrephss×1]
      idrephss2sec = secmgr.idMapper_.idrephss2sec;
    end
    function idrephss2var = get.idrephss2var(secmgr)
      %get.idrephss2var - 代表HSS断面→変数を取得する
      %
      %   idrephss2var = secmgr.idrephss2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrephss2var - 代表HSS断面→変数 [nrephss×2]
      idrephss2var = secmgr.idMapper_.idrephss2var;
    end
    function idrephss2hss = get.idrephss2hss(secmgr)
      %get.idrephss2hss - 代表HSS断面→HSS断面を取得する
      %
      %   idrephss2hss = secmgr.idrephss2hss
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrephss2hss - 代表HSS断面→HSS断面 [nrephss×1]
      idrephss2hss = secmgr.idMapper_.idrephss2hss;
    end
    %---
    function idrepwfs2sec = get.idrepwfs2sec(secmgr)
      %get.idrepwfs2sec - 代表WFS断面→断面を取得する
      %
      %   idrepwfs2sec = secmgr.idrepwfs2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrepwfs2sec - 代表WFS断面→断面 [nrepwfs×1]
      idrepwfs2sec = secmgr.idMapper_.idrepwfs2sec;
    end
    function idrepwfs2var = get.idrepwfs2var(secmgr)
      %get.idrepwfs2var - 代表WFS断面→変数を取得する
      %
      %   idrepwfs2var = secmgr.idrepwfs2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrepwfs2var - 代表WFS断面→変数 [nrepwfs×4]
      idrepwfs2var = secmgr.idMapper_.idrepwfs2var;
    end
    function idrepwfs2wfs = get.idrepwfs2wfs(secmgr)
      %get.idrepwfs2wfs - 代表WFS断面→WFS断面を取得する
      %
      %   idrepwfs2wfs = secmgr.idrepwfs2wfs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrepwfs2wfs - 代表WFS断面→WFS断面 [nrepwfs×1]
      idrepwfs2wfs = secmgr.idMapper_.idrepwfs2wfs;
    end
    %---
    function idreprcrs2sec = get.idreprcrs2sec(secmgr)
      %get.idreprcrs2sec - 代表RCRS断面→断面を取得する
      %
      %   idreprcrs2sec = secmgr.idreprcrs2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idreprcrs2sec - 代表RCRS断面→断面 [nreprcrs×1]
      idreprcrs2sec = secmgr.idMapper_.idreprcrs2sec;
    end
    function idreprcrs2rcrs = get.idreprcrs2rcrs(secmgr)
      %get.idreprcrs2rcrs - 代表RCRS断面→RCRS断面を取得する
      %
      %   idreprcrs2rcrs = secmgr.idreprcrs2rcrs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idreprcrs2rcrs - 代表RCRS断面→RCRS断面 [nreprcrs×1]
      idreprcrs2rcrs = secmgr.idMapper_.idreprcrs2rcrs;
    end
    %---
    function idrepbrbs2sec = get.idrepbrbs2sec(secmgr)
      %get.idrepbrbs2sec - 代表BRB断面→断面を取得する
      %
      %   idrepbrbs2sec = secmgr.idrepbrbs2sec
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrepbrbs2sec - 代表BRB断面→断面 [nrepbrbs×1]
      idrepbrbs2sec = secmgr.idMapper_.idrepbrbs2sec;
    end
    function idrepbrbs2var = get.idrepbrbs2var(secmgr)
      %get.idrepbrbs2var - 代表BRB断面→変数を取得する
      %
      %   idrepbrbs2var = secmgr.idrepbrbs2var
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrepbrbs2var - 代表BRB断面→変数 [nrepbrbs×2]
      idrepbrbs2var = secmgr.idMapper_.idrepbrbs2var;
    end
    function idrepbrbs2brbs = get.idrepbrbs2brbs(secmgr)
      %get.idrepbrbs2brbs - 代表BRB断面→BRB断面を取得する
      %
      %   idrepbrbs2brbs = secmgr.idrepbrbs2brbs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idrepbrbs2brbs - 代表BRB断面→BRB断面 [nrepbrbs×1]
      idrepbrbs2brbs = secmgr.idMapper_.idrepbrbs2brbs;
    end

    %% PropertyCalculatorへの委譲（材料関連）
    % 材料プロパティ取得
    function mat = get.material(secmgr)
      %get.material - 材料データ構造体を取得する
      %
      %   mat = secmgr.material
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     mat - 材料データ構造体
      mat = secmgr.propertyCalculator_.material;
    end

    % 断面リストの材料情報取得
    function idmat = getIdSecList2Material(secmgr, idslist)
      %getIdSecList2Material - 断面リストの材料番号を取得する
      %
      %   idmat = getIdSecList2Material(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     idmat - 材料番号
      idmat = secmgr.propertyCalculator ...
        .extractSectionListMaterialId(idslist);
    end
    function F = getIdSecList2F(secmgr, idslist)
      %getIdSecList2F - 断面リストの材料F値を取得する
      %
      %   F = getIdSecList2F(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     F - 材料のF値 (N/mm²)
      F = secmgr.propertyCalculator.extractSectionListMaterialF(idslist);
    end

    function isSN = getIdSecList2isSN(secmgr, idslist)
      %getIdSecList2isSN - 断面リストのSN材判定を取得する
      %
      %   isSN = getIdSecList2isSN(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     isSN - SN材を示す論理配列
      isSN = secmgr.propertyCalculator.extractSectionListIsSN(idslist);
    end

    function grade = getIdSecList2Grade(secmgr, idslist)
      %getIdSecList2Grade - 断面リストの材料グレードを取得する
      %
      %   grade = getIdSecList2Grade(secmgr, idslist)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %
      %   出力引数:
      %     grade - 材料のグレード
      grade = secmgr.propertyCalculator.extractSectionListGrade(idslist);
    end

    % コスト係数・応力係数取得
    function sectionCostFactor = getSectionCostFactor(secmgr, idsec2slist)
      %getSectionCostFactor - 断面コスト係数を取得
      %   sectionCostFactor = getSectionCostFactor( ...
      %     secmgr, idsec2slist)
      %   は、断面リストIDと断面IDのペアから断面のコスト係数を返す。
      %
      %   参考:
      %     SectionPropertyCalculator.getSectionCostFactor
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idsec2slist - 断面リストID/断面IDペア配列 [n × 2]
      %
      %   出力引数:
      %     sectionCostFactor - 各断面のコスト係数 [n × 1]

      sectionCostFactor = ...
        secmgr.propertyCalculator.getSectionCostFactor(idsec2slist);
    end

    function memberCostFactor = getMemberCostFactor(secmgr, ...
      idsec2slist, member)
      %getMemberCostFactor - 部材コスト係数を現在の部材順に取得する
      %
      %   memberCostFactor = getMemberCostFactor(secmgr, ...
      %   idsec2slist, member)
      %   は、断面リストの係数をmemberの断面番号で参照する。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idsec2slist - 断面リストと候補断面の番号 [nsec×2]
      %     member - 現在の解析部材。property.idsecを参照する。
      %
      %   出力引数:
      %     memberCostFactor - 部材コスト係数 [nme×1]

      memberCostFactor = secmgr.propertyCalculator.getMemberCostFactor( ...
        idsec2slist, member);
    end

    function memberCostConstant = getMemberCostConstant( ...
        secmgr, idsec2slist, member)
      %getMemberCostConstant - 部材コスト定数を現在の部材順に取得する
      %
      %   memberCostConstant = getMemberCostConstant( ...
      %   secmgr, idsec2slist, member)
      %   は、断面リストの定数をmemberの断面番号で参照する。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idsec2slist - 断面リストと候補断面の番号 [nsec×2]
      %     member - 現在の解析部材。property.idsecを参照する。
      %
      %   出力引数:
      %     memberCostConstant - 部材コスト定数 [nme×1]

      memberCostConstant = ...
        secmgr.propertyCalculator.getMemberCostConstant( ...
        idsec2slist, member);
    end

    function sectionStressFactor = getSectionStressFactor( ...
        secmgr, idsec2slist)
      %getSectionStressFactor - 断面応力係数を取得
      %   sectionStressFactor = getSectionStressFactor(secmgr, idsec2slist)
      %   は、断面リストIDと断面IDのペアから各断面の応力係数を取得します。
      %
      %   参考:
      %     SectionPropertyCalculator.getSectionStressFactor
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idsec2slist - 断面リストID/断面IDペア配列 [n × 2]
      %
      %   出力引数:
      %     sectionStressFactor - 各断面の応力係数 [n × 1]

      sectionStressFactor = ...
        secmgr.propertyCalculator.getSectionStressFactor(idsec2slist);
    end

    % 断面・部材の材料情報抽出
    function [F, idmat] = extractSectionMaterialF(secmgr, secdim, matF)
      %extractSectionMaterialF - 全断面の材料F値と材料番号を取得する
      %
      %   [F, idmat] = extractSectionMaterialF(secmgr, secdim, matF)
      %   は、断面性能計算オブジェクトに材料取得を委譲する。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     secdim - 写像済みの全断面寸法 [nsec×7] (mm)
      %     matF   - 材料のF値 [nmat×1] (N/mm²)
      %
      %   出力引数:
      %     F     - 断面のF値 [nsec×1] (N/mm²)
      %     idmat - 断面の材料番号 [nsec×1]（未割当は0）
      %
      %   参考:
      %     SectionPropertyCalculator.extractSectionMaterialF

      [F, idmat] = secmgr.propertyCalculator.extractSectionMaterialF( ...
        secdim, matF);

      return
    end
    function idMemberToMaterial = getIdMemberToMaterial( ...
        secmgr, idsec2slist, member)
      %getIdMemberToMaterial - 部材の材料番号を現在の部材順に取得する
      %
      %   idMemberToMaterial = getIdMemberToMaterial( ...
      %   secmgr, idsec2slist, member)
      %   は、採用断面の材料をmemberの断面番号で参照する。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idsec2slist - 断面リストと候補断面の番号 [nsec×2]
      %     member - 現在の解析部材。property.idsecを参照する。
      %
      %   出力引数:
      %     idMemberToMaterial - 部材の材料番号 [nme×1]

      idMemberToMaterial = secmgr.propertyCalculator ...
        .extractMemberMaterialId(idsec2slist, member);
    end

    function idMemberToSubList = getIdMemberToSubList(secmgr, ...
      idsec2slist, member)
      %getIdMemberToSubList - 部材のサブリスト番号を現在の部材順に取得する
      %
      %   idMemberToSubList = getIdMemberToSubList(secmgr, ...
      %   idsec2slist, member)
      %   は、採用断面のサブリストをmemberの断面番号で参照する。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idsec2slist - 断面リストと候補断面の番号 [nsec×2]
      %     member - 現在の解析部材。property.idsecを参照する。
      %
      %   出力引数:
      %     idMemberToSubList - 部材のサブリスト番号 [nme×1]

      idMemberToSubList = ...
        secmgr.idMapper.mapIdMemberToSubList(idsec2slist, member);
    end

    function F = extractMemberMaterialF(secmgr, secdim, matF, member)
      %extractMemberMaterialF - 現在の部材の材料F値を取得する
      %
      %   F = extractMemberMaterialF(secmgr, secdim, matF, member)
      %   は、採用寸法の材料F値をmemberの断面番号で参照する。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     secdim - 写像済みの断面寸法 [nsec×7]
      %     matF - 材料のF値 [nmat×1] (N/mm²)
      %     member - 現在の解析部材。property.idsecを参照する。
      %
      %   出力引数:
      %     F - 部材順のF値 [nme×1] (N/mm²)

      F = secmgr.propertyCalculator.extractMemberMaterialF(secdim, ...
        matF, member);
    end

    function grade = extractMemberMaterialGrade(secmgr, secdim, ...
      matGrade, member)
      %extractMemberMaterialGrade - 現在の部材の鋼種を取得する
      %
      %   grade = extractMemberMaterialGrade(secmgr, secdim, ...
      %   matGrade, member)
      %   は、採用寸法の鋼種をmemberの断面番号で参照する。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     secdim - 写像済みの断面寸法 [nsec×7]
      %     matGrade - 材料別の鋼種番号 [nmat×1]
      %     member - 現在の解析部材。property.idsecを参照する。
      %
      %   出力引数:
      %     grade - 部材順の鋼種番号 [nme×1]

      grade = secmgr.propertyCalculator ...
        .extractMemberMaterialGrade(secdim, matGrade, member);
    end

    %% 断面リストID変換（deprecatedと新実装混在）
    function idwfs2slist = get.idwfs2slist(secmgr)
      %get.idwfs2slist - WFS断面→断面リストIDを取得する
      %
      %   idwfs2slist = secmgr.idwfs2slist
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idwfs2slist - WFS断面→断面リストID [nwfs×1]
      idwfs2slist = secmgr.idMapper_.idwfs2slist;
    end
    function idhss2slist = get.idhss2slist(secmgr)
      %get.idhss2slist - HSS断面→断面リストIDを取得する
      %
      %   idhss2slist = secmgr.idhss2slist
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idhss2slist - HSS断面→断面リストID [nhss×1]
      idhss2slist = secmgr.idMapper_.idhss2slist;
    end
    function idbrbs2slist = get.idbrbs2slist(secmgr)
      %get.idbrbs2slist - BRB断面→断面リストIDを取得する
      %
      %   idbrbs2slist = secmgr.idbrbs2slist
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     idbrbs2slist - BRB断面→断面リストID [nbrbs×1]
      idbrbs2slist = secmgr.idMapper_.idbrbs2slist;
    end

    %% 近傍探索系メソッド（委譲のみ）
    function [xlist, idvlist, sdlist] = generateNeighborhoodSet( ...
        secmgr, xvar, isvar, options, initial_guess, com)
      %generateNeighborhoodSet - 近傍断面集合の生成
      %   [xlist, idvlist, sdlist] = generateNeighborhoodSet(secmgr, ...
      %     xvar, isvar, options, initial_guess, com) は、
      %   指定された変数値から近傍断面の集合を生成します。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar    - 現在の変数値 [1×nxvar]
      %     isvar   - 変数の有効フラグ [nxvar×1] 論理値配列
      %     options - オプション構造体
      %     initial_guess - 基点の設計変数と断面寸法の組（省略可能）
      %     com - worker用constantを持つ架構情報（省略可能）
      %
      %   参考:
      %     SectionNeighborSearcher.generateNeighborhoodSet
      %
      %   出力引数:
      %     xlist - 近傍断面の変数値リスト [nlist×nxvar]
      %     idvlist - 変数IDリスト [nlist×1]
      %     sdlist - 最近傍断面の寸法リスト [nsec×ndim×nlist]

      if nargin < 5
        initial_guess = [];
      end
      if nargin < 6
        com = [];
      end
      [xlist, idvlist, sdlist] = secmgr.neighborSearcher ...
        .generateNeighborhoodSet(xvar, isvar, options, initial_guess, com);
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
      %findNearestSectionWfs - WFS断面の最近傍選択
      %   [wfsec, repwfs, id] = findNearestSectionWfs(secmgr, xvar,
      %     idslist, options) は、WFS断面の最近傍を選択します。
      %
      %   参考:
      %     SectionNeighborSearcher.findNearestSectionWfs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar - 設計変数ベクトル [nxvar×1]（公称値）
      %     idslist - 断面リストID (スカラー)
      %     options - オプション構造体（tolHgap、tolBgapを含む）
      %
      %   出力引数:
      %     wfsec - WFS断面寸法 [nwfs×5]（実寸値）
      %     repwfs - 代表WFS断面 [nrepwfs×5]（実寸値）
      %     id - ID構造体（.slist, .section）

      [wfsec, repwfs, id] = ...
        secmgr.neighborSearcher.findNearestSectionWfs(...
          xvar, idslist, options);
    end

    function [hssec, rephss, id] = findNearestSectionHss( ...
        secmgr, xvar, idslist, options)
      %findNearestSectionHss - HSS断面の最近傍選択
      %   [hssec, rephss, id] = findNearestSectionHss(secmgr, xvar,
      %     idslist, options) は、HSS断面の最近傍を選択します。
      %
      %   参考:
      %     SectionNeighborSearcher.findNearestSectionHss
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar - 設計変数ベクトル [nxvar×1]
      %     idslist - 断面リストID（スカラー）
      %     options - オプション構造体（tolDgap等）
      %
      %   出力引数:
      %     hssec - HSS断面寸法 [nhss×5]（列1-3使用、4-5は互換性用）
      %     rephss - 代表HSS断面 [nrephss×5]（列1-3使用、4-5は互換性用）
      %     id - ID構造体（.slist, .section）

      [hssec, rephss, id] = ...
        secmgr.neighborSearcher.findNearestSectionHss(...
          xvar, idslist, options);
    end

    function [brbsec, repbrbs, id] = findNearestSectionBrb( ...
        secmgr, xvar, idslist, options)
      %findNearestSectionBrb - BRB断面の最近傍選択
      %   [brbsec, repbrbs, id] = findNearestSectionBrb(secmgr, xvar,
      %     idslist, options) は、BRB断面の最近傍を選択します。
      %
      %   参考:
      %     SectionNeighborSearcher.findNearestSectionBrb
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar - 設計変数ベクトル [nxvar×1]
      %     idslist - 断面リストID (スカラー)
      %     options - オプション構造体（BRBでは未使用）
      %
      %   出力引数:
      %     brbsec - BRB断面寸法 [nbrbs×4]
      %     repbrbs - 代表BRB断面 [nrepbrbs×4]
      %     id - ID構造体（.slist, .section）

      [brbsec, repbrbs, id] = ...
        secmgr.neighborSearcher.findNearestSectionBrb(...
          xvar, idslist, options);
    end

    function sdlist = findNearestSectionList(secmgr, xlist, ...
        options, initial_guess, com)
      %findNearestSectionList - 候補の設計変数から断面だけを選択する
      %
      %   sdlist = findNearestSectionList(secmgr, xlist, options,
      %     initial_guess, com) は、各候補を変更せず規格断面へ写像する。
      %
      %   入力引数:
      %     secmgr - SectionManagerインスタンス
      %     xlist - 候補の設計変数 [nlist×nxvar]
      %     options - 共通オプション
      %     initial_guess - 基点の設計変数と断面。省略可能
      %     com - workerへ配布する共通データ。省略可能
      %
      %   出力引数:
      %     sdlist - 候補別の断面寸法 [nsec×7×nlist]
      %
      %   参考:
      %     SectionNeighborSearcher.findNearestSectionList

      if nargin < 4
        initial_guess = [];
      end
      if nargin < 5
        com = [];
      end
      sdlist = secmgr.neighborSearcher.findNearestSectionList( ...
        xlist, options, initial_guess, com);

      return
    end

    function [xlist, sdlist] = findNearestXList(secmgr, xlist, ...
        options, initial_guess, com)
      %findNearestXList - 変数リストから最近傍断面を選択
      %   [xlist, sdlist] = findNearestXList(secmgr, xlist, ...
      %     options, initial_guess, com) は、
      %   変数値リストの各要素について最近傍の規格断面を選択します。
      %
      %   参考:
      %     SectionNeighborSearcher.findNearestXList
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xlist - 候補ごとの設計変数 [n候補×nxvar]
      %     options - 共通オプション
      %     initial_guess - 共通基点（.x、.secdim）。省略可能
      %     com - worker用constantを持つ共通構造体。省略可能
      %
      %   出力引数:
      %     xlist - 写像後の変数値リスト [nlist×nxvar]
      %     sdlist - 写像済み断面寸法 [nsec×7×nlist]

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
      %     secmgr - 断面管理オブジェクト
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
      %findNearestXvarofWfs - WFS断面の最近傍変数値を検索
      %   xvar = findNearestXvarofWfs(secmgr, repwfs, xvar0, options) は、
      %   WFS断面の代表断面から最近傍の変数値を検索します。
      %
      %   参考:
      %     SectionNeighborSearcher.findNearestXvarofWfs
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     repwfs - WFS代表断面の寸法データ
      %     xvar0 - 初期変数値（空の場合はゼロ初期化）
      %     options - オプション構造体
      %
      %   出力引数:
      %     xvar - 最近傍の変数値ベクトル [1×nxvar]

      % SectionNeighborSearcherに委譲
      xvar = secmgr.neighborSearcher.findNearestXvarofWfs(...
        repwfs, xvar0, options);
    end

    function xvar = findNearestXvarofHss(secmgr, rephss, xvar0, options)
      %findNearestXvarofHss - HSS断面の最近傍変数値を検索
      %   xvar = findNearestXvarofHss(secmgr, rephss, xvar0, options) は、
      %   HSS断面の代表断面から最近傍の変数値を検索します。
      %
      %   参考:
      %     SectionNeighborSearcher.findNearestXvarofHss
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     rephss - HSS代表断面の寸法データ
      %     xvar0 - 初期変数値（空の場合はゼロ初期化）
      %     options - オプション構造体
      %
      %   出力引数:
      %     xvar - 最近傍の変数値ベクトル [1×nxvar]

      % SectionNeighborSearcherに委譲
      xvar = secmgr.neighborSearcher.findNearestXvarofHss(...
        rephss, xvar0, options);
    end

    function xvar = findNearestXvarofBrb(secmgr, repbrbs, xvar0, options)
      %findNearestXvarofBrb - BRB断面の最近傍変数値を検索
      %   xvar = findNearestXvarofBrb(secmgr, repbrbs, xvar0, options) は、
      %   BRB断面の代表断面から最近傍の変数値を検索します。
      %
      %   参考:
      %     SectionNeighborSearcher.findNearestXvarofBrb
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     repbrbs - BRB代表断面の寸法データ
      %     xvar0 - 初期変数値（空の場合はゼロ初期化）
      %     options - オプション構造体
      %
      %   出力引数:
      %     xvar - 最近傍の変数値ベクトル [1×nxvar]

      % SectionNeighborSearcherに委譲
      xvar = secmgr.neighborSearcher.findNearestXvarofBrb(...
        repbrbs, xvar0, options);
    end

    %% 近傍探索系メソッド（委譲のみ）
    function [xlist, xup, xdw, idvlist] = enumerateNeighborH( ...
        secmgr, xvar, idvar, options, delta)
      %enumerateNeighborH - 梁せいHの近傍断面を列挙
      %   [xlist, xup, xdw, idvlist] = enumerateNeighborH(secmgr, xvar,
      %     idvar, options, delta) は、梁せいHの近傍断面を列挙します。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar    - 現在の変数値 [1×nxvar]
      %     idvar   - 対象変数ID (スカラー)
      %     options - オプション構造体
      %     delta   - 探索範囲 (mm、省略可能、既定値: 150)
      %
      %   参考:
      %     SectionNeighborSearcher.enumerateNeighborH
      %
      %   出力引数:
      %     xlist - 上下の候補行 [n×nx]
      %     xup - 上側の候補行 [nup×nx]
      %     xdw - 下側の候補行 [ndw×nx]
      %     idvlist - 上下の候補行番号（up, dw）

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
      %enumerateNeighborB - フランジ幅Bの近傍断面を列挙
      %   [xlist, xup, xdw, idvlist] = enumerateNeighborB(secmgr, xvar,
      %     idvar, options) は、フランジ幅Bの近傍断面を列挙します。
      %
      %   参考:
      %     SectionNeighborSearcher.enumerateNeighborB
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar - 現在の変数値 [nvar×1]
      %     idvar - 対象変数ID (スカラー)
      %     options - オプション構造体
      %
      %   出力引数:
      %     xlist - 近傍解の変数値リスト [n×nvar]
      %     xup - 上位方向の近傍解 [nup×nvar]
      %     xdw - 下位方向の近傍解 [ndw×nvar]
      %     idvlist - インデックス構造体

      % neighborSearcherに委譲
      [xlist, xup, xdw, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborB(xvar, idvar, options);
    end

    function [xlist, xup, xdw, idvlist] = enumerateNeighborD( ...
        secmgr, xvar, idvar, options)
      %enumerateNeighborD - 径Dの近傍断面を列挙
      %   [xlist, xup, xdw, idvlist] = enumerateNeighborD(secmgr, xvar,
      %     idvar, options) は、径Dの近傍断面を列挙します。
      %
      %   参考:
      %     SectionNeighborSearcher.enumerateNeighborD
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar - 現在の変数値 [1×nx]
      %     idvar - 対象変数ID（空なら候補なし）
      %     options - 共通オプション（未使用）
      %
      %   出力引数:
      %     xlist - 上下の候補行 [n×nx]
      %     xup - 上側の候補行 [nup×nx]
      %     xdw - 下側の候補行 [ndw×nx]
      %     idvlist - 上下の候補行番号（up, dw）

      % neighborSearcherに委譲
      [xlist, xup, xdw, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborD(xvar, idvar, options);
    end

    function [xlist, xup, xdw, idvartarget, idvlist] = ...
      enumerateNeighborT(secmgr, xvar, idvar, options)
      %enumerateNeighborT - 厚さtの近傍断面を列挙
      %   [xlist, xup, xdw, idvartarget, idvlist] = enumerateNeighborT(
      %     secmgr, xvar, idvar, options) は、厚さtの近傍断面を列挙します。
      %
      %   参考:
      %     SectionNeighborSearcher.enumerateNeighborT
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar - 現在の変数値 [nvar×1]
      %     idvar - 対象変数ID (スカラー)
      %     options - オプション構造体
      %
      %   出力引数:
      %     xlist - 近傍解の変数値リスト [n×nvar]
      %     xup - 上位方向の近傍解 [nup×nvar]
      %     xdw - 下位方向の近傍解 [ndw×nvar]
      %     idvartarget - 対象変数IDリスト
      %     idvlist - インデックス構造体

      % neighborSearcherに委譲
      [xlist, xup, xdw, idvartarget, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborT(xvar, idvar, options);
    end

    function [xlist, xup, xdw, idvartarget, idvlist] = ...
      enumerateNeighborTw(secmgr, xvar, idvar, options)
      %enumerateNeighborTw - ウェブ厚twの近傍断面を列挙
      %   [xlist, xup, xdw, idvartarget, idvlist] = enumerateNeighborTw(
      %     secmgr, xvar, idvar, options) は、
      %     ウェブ厚twの近傍断面を列挙します。
      %
      %   参考:
      %     SectionNeighborSearcher.enumerateNeighborTw
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar - 現在の変数値 [nvar×1]
      %     idvar - 対象変数ID (スカラー)
      %     options - オプション構造体
      %
      %   出力引数:
      %     xlist - 近傍解の変数値リスト [n×nvar]
      %     xup - 上位方向の近傍解 [nup×nvar]
      %     xdw - 下位方向の近傍解 [ndw×nvar]
      %     idvartarget - 対象変数IDリスト
      %     idvlist - インデックス構造体

      % neighborSearcherに委譲
      [xlist, xup, xdw, idvartarget, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborTw(...
          xvar, idvar, options);
    end

    function [xlist, xup, xdw, idvartarget, idvlist] = ...
      enumerateNeighborTf(secmgr, xvar, idvar, options)
      %enumerateNeighborTf - フランジ厚tfの近傍断面を列挙
      %   [xlist, xup, xdw, idvartarget, idvlist] = enumerateNeighborTf(
      %     secmgr, xvar, idvar, options) は、
      %     フランジ厚tfの近傍断面を列挙します。
      %
      %   参考:
      %     SectionNeighborSearcher.enumerateNeighborTf
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     xvar - 現在の変数値 [nvar×1]
      %     idvar - 対象変数ID (スカラー)
      %     options - オプション構造体
      %
      %   出力引数:
      %     xlist - 近傍解の変数値リスト [n×nvar]
      %     xup - 上位方向の近傍解 [nup×nvar]
      %     xdw - 下位方向の近傍解 [ndw×nvar]
      %     idvartarget - 対象変数IDリスト
      %     idvlist - インデックス構造体

      % neighborSearcherに委譲
      [xlist, xup, xdw, idvartarget, idvlist] = ...
        secmgr.neighborSearcher_.enumerateNeighborTf(...
          xvar, idvar, options);
    end

    %% データアクセス系メソッド（委譲のみ）
    function [dimension, idsection] = getDimension(secmgr, idList, idphase)
      %getDimension - 断面寸法を取得
      %   [dimension, idsection] = getDimension(secmgr, idList, idphase)
      %   は、断面リストの寸法と候補断面表の行番号を取得します。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idList  - 断面リストID
      %     idphase - フェーズID（省略可能、既定値: secmgr.idphase）
      %
      %   参考:
      %     SectionStandardAccessor.getSectionDimension
      %
      %   出力引数:
      %     dimension - 断面リストから取得した候補断面寸法
      %     idsection - 候補断面表の行番号

      % StandardAccessorに委譲
      if nargin == 2
        [dimension, idsection] = ...
          secmgr.standardAccessor.getSectionDimension(idList);
      else
        [dimension, idsection] = secmgr.standardAccessor ...
          .getSectionDimension(idList, idphase);
      end
    end

    function [stvals, stnum] = getStandardValues(secmgr)
      %getStandardValues - 全断面リストの規格値セットを取得
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
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト

      % StandardAccessorに委譲
      [stvals, stnum] = secmgr.standardAccessor.getStandardValues();
    end

    function record = getListRecord(secmgr, secdim)
      %getListRecord - 断面テーブルレコードを取得
      %   record = getListRecord(secmgr, secdim) は、
      %   secdim の末尾2列（断面リストID, 断面ID）から
      %   対応するテーブルレコードを取得します。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
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
      %initValidSectionFlagCell - 有効断面フラグセルの初期化
      %   initValidSectionFlagCell(secmgr) は、有効断面フラグセルの初期化を
      %   SectionConstraintValidatorに委譲します。
      %
      %   例:
      %     secmgr.initValidSectionFlagCell();
      %
      %   参考:
      %     SectionConstraintValidator.initValidSectionFlagCell
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %
      %   出力引数:
      %     なし

      % SectionConstraintValidatorに委譲
      secmgr.constraintValidator.initValidSectionFlagCell();
    end

    %% 制約チェック系メソッド（委譲のみ）
    function isvalid = getValidSectionOfSlist(secmgr, idslist, idphase)
      %getValidSectionOfSlist - 有効断面リストを取得
      %   isvalid = getValidSectionOfSlist(secmgr, idslist, idphase) は、
      %   指定された断面リストの有効フラグを取得します。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     idslist - 断面リストID
      %     idphase - フェーズID（省略可能、既定値: secmgr.idphase）
      %
      %   参考:
      %     SectionConstraintValidator.extractValidSectionFlags
      %
      %   出力引数:
      %     isvalid - 候補断面の有効・無効を示す論理配列

      if nargin == 2
        isvalid = secmgr.constraintValidator ...
          .extractValidSectionFlags(idslist);
      else
        isvalid = secmgr.constraintValidator ...
          .extractValidSectionFlags(idslist, idphase);
      end
    end

    function limit_jbs_section(secmgr, isjbs, nominal_girder, ...
        section_girder, section_column, member, options, apply_filter)
      %limit_jbs_section - 保有耐力接合(JBS)制限チェック
      %
      %   limit_jbs_section(secmgr, isjbs,
      %   nominal_girder, section_girder,
      %   section_column, member, options) は、保有耐力接合の
      %   制限チェックを実行します。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     isjbs          - JBS判定対象フラグ [nng×2]
      %     nominal_girder - 名目梁テーブル
      %     section_girder - 梁断面構造体
      %     section_column - 柱断面構造体
      %     member         - 柱形状と梁端節点を含む部材情報
      %     options        - オプション構造体
      %     apply_filter   - 候補リスト更新フラグ（省略時true）
      %
      %   参考:
      %     SectionConstraintValidator.limitJbsSection
      %
      %   出力引数:
      %     なし

      if nargin < 8
        apply_filter = true;
      end

      % constraintValidatorへ委譲
      secmgr.constraintValidator.limitJbsSection(isjbs, ...
        nominal_girder, section_girder, section_column, member, secmgr, ...
        options, apply_filter);
    end

    function limit_slr_section(secmgr, member, nominal, lm, options)
      %limit_slr_section - 細長比制限チェック
      %
      %   limit_slr_section(secmgr, member, nominal, lm, options)
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     member - 現在の解析部材の情報
      %     nominal - 名目部材の情報
      %     lm - 現在の解析部材の長さ (mm)
      %     options - 解析・探索オプション
      %
      %   出力引数:
      %     なし

      % constraintValidatorへ委譲
      secmgr.constraintValidator.limitSlrSection(member, ...
        nominal, lm, secmgr, options);
    end

    function limit_wtratio_section(secmgr, section, options)
      %limit_wtratio_section - 幅厚比制限チェック
      %   limit_wtratio_section(secmgr, section, options) は、
      %   幅厚比の制限チェックを実行します。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     section - 断面情報構造体
      %     options - オプション構造体
      %
      %   参考:
      %     SectionConstraintValidator.limitWtRatioSection
      %
      %   出力引数:
      %     なし

      % constraintValidatorへ委譲
      secmgr.constraintValidator.limitWtRatioSection( ...
        section, options, secmgr);
    end

    %% ユーティリティメソッド
    function x = generateRandomXvar(secmgr, seed, member, lm, options)
      %generateRandomXvar - 同じ幾何状態の部材と長さから初期解を作る
      %
      %   x = generateRandomXvar(secmgr, seed, member, lm, options)
      %   は、memberの変数対応とlmを渡し、設定に従って初期値を選ぶ。
      %
      %   入力引数:
      %     secmgr - 断面管理オブジェクト
      %     seed - 乱数シード。空の場合はshuffleを使用する。
      %     member - lmと同じ断面・分割状態の解析部材
      %     lm - memberの部材順に並ぶ長さ [nme×1] (mm)
      %     options - 初期解の梁せい制限を含む計算条件
      %
      %   出力引数:
      %     x - 初期設計変数 [1×nxvar]

      x = generate_random_initial_solution(secmgr.standardAccessor_, ...
        secmgr.idMapper_, secmgr.secList, seed, member, lm, options);
    end
  end
end
