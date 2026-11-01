classdef IdMapper < handle
  %IdMapper ID変換・マッピング機能を提供するクラス
  %   IdMapperは、断面、部材、変数間のID変換とマッピングを
  %   管理する専門クラスです。異なる断面タイプ（WFS、HSS、
  %   RCRS、BRB）間の相互変換や、部材から断面への対応付けを
  %   効率的に処理します。
  %
  %   IdMapper プロパティ:
  %     nsec - 総断面数
  %     nwfs - WFS断面数
  %     nhss - HSS断面数
  %     nrcrs - RCRS断面数
  %     nbrbs - BRB断面数
  %     nxvar - 変数数
  %     idSectionList - 断面→断面リストIDマッピング [nsec×1]
  %     idsec2stype - 断面→断面タイプマッピング [nsec×1]
  %     idsec2shape - 断面→断面リストの鉄骨形状 [nsec×1]
  %     idsec2srep - 断面→代表断面マッピング [nsec×1]
  %     idvar2vtype - 変数→変数タイプマッピング [nxvar×1]
  %
  %   IdMapper メソッド:
  %     lookupSectionType - 断面→断面タイプ参照
  %     lookupVariableType - 変数→変数タイプ参照
  %     mapSectionToWfs - 断面→WFS断面変換
  %     mapSectionToHss - 断面→HSS断面変換
  %     mapWfsToSection - WFS断面→断面変換
  %     mapHssToSection - HSS断面→断面変換
  %     mapMemberToSection - memberから断面番号を取得
  %     mapMemberToSectionType - memberから断面種別を取得
  %     mapIdMemberToSubList - memberからリスト内断面番号を取得
  %
  %   参考:
  %     SectionConstraintValidator, SectionManager

  properties (Access = private)
    % 基本的なマッピング配列（外部から提供）
    idSectionList_ % 断面→断面リストID [nsec×1]（静的）
    idsec2stype_   % 断面→断面タイプ [nsec×1]
    idsec2srep_    % 断面→代表断面 [nsec×1]
    idvar2vtype_   % 変数→変数タイプ [nxvar×1]

    % 事前計算されたマッピング（コンストラクタで計算）
    idwfs2repwfs_  % WFS断面→代表WFS断面 [nwfs×1]
    idrepwfs2wfs_  % 代表WFS→最初のWFS断面 [nrepwfs×1]
    idhss2rephss_  % HSS断面→代表HSS断面 [nhss×1]
    idrephss2hss_  % 代表HSS→最初のHSS断面 [nrephss×1]
    idbrbs2repbrbs_ % BRB断面→代表BRB断面 [nbrbs×1]
    idrepbrbs2brbs_ % 代表BRB→最初のBRB断面 [nrepbrbs×1]
    idhsr2rephsr_  % HSR断面→代表HSR断面 [nhsr×1]
    idrephsr2hsr_  % 代表HSR→最初のHSR断面 [nrephsr×1]
    idsrep2sec_    % 代表断面→断面 [nsrep×1]
    idsec2var_     % 断面→変数 [nsec×ndim]
    idsrep2var_    % 代表断面→変数 [nsrep×ndim]
    idsrep2stype_  % 代表断面→断面タイプ [nsrep×1]
    idsec2shape_   % 断面→断面リストの鉄骨形状 [nsec×1]（リストなしは0）
    idsrep2shape_  % 代表断面→断面リストの鉄骨形状 [nsrep×1]
    idrepwfs2var_  % 代表WFS断面→変数 [nrepwfs×ndim]
    idrephss2var_  % 代表HSS断面→変数 [nrephss×ndim]
    idrepbrbs2var_ % 代表BRB断面→変数 [nrepbrbs×ndim]
    idrephsr2var_  % 代表HSR断面→変数 [nrephsr×2]

    % 変数IDマッピング配列
    idH2var_       % H変数ID配列（WFS断面）
    idB2var_       % B変数ID配列（WFS断面）
    idtw2var_      % tw変数ID配列（WFS断面）
    idtf2var_      % tf変数ID配列（WFS断面）
    idD2var_       % D変数ID配列（HSS断面）
    idt2var_       % t変数ID配列（HSS断面）
    idHsrD2var_    % HSR D変数ID配列（HSR断面）
    idHsrt2var_    % HSR t変数ID配列（HSR断面）
    idBrb1_var_    % BRB V1変数ID配列
    idBrb2_var_    % BRB V2変数ID配列
    idvar2srep_    % 変数→代表断面 cell配列
    idsublistCell  % サブリストIDのcell配列 {nlist×1}
  end

  properties (Dependent)
    % 数カウント（動的計算）
    nsec          % 総断面数
    nwfs          % WFS断面数
    nhss          % HSS断面数
    nrcrs         % RCRS断面数
    nbrbs         % BRB断面数
    nhsr          % HSR断面数
    nxvar         % 変数数
    nsrep         % 代表断面数
    nrepwfs       % 代表WFS断面数
    nrephss       % 代表HSS断面数
    nrepbrbs      % 代表BRB断面数
    nrephsr       % 代表HSR断面数
    nlist         % 断面リスト数

    % 基本データへの読み取り専用アクセス
    idSectionList % 断面→断面リストID [nsec×1]（静的）
    idsec2stype   % 断面→断面タイプ [nsec×1]
    idsec2shape   % 断面→断面リストの鉄骨形状 [nsec×1]（リストなしは0）
    idsec2srep    % 断面→代表断面 [nsec×1]
    idvar2vtype   % 変数→変数タイプ [nxvar×1]
    idsrep2sec    % 代表断面→断面 [nsrep×1]
    idsec2var     % 断面→変数 [nsec×ndim]

    % 変数IDマッピングプロパティ
    idH2var       % H変数ID配列（WFS断面）
    idB2var       % B変数ID配列（WFS断面）
    idtw2var      % tw変数ID配列（WFS断面）
    idtf2var      % tf変数ID配列（WFS断面）
    idD2var       % D変数ID配列（HSS断面）
    idt2var       % t変数ID配列（HSS断面）
    idHsrD2var    % HSR D変数ID配列（HSR断面）
    idHsrt2var    % HSR t変数ID配列（HSR断面）
    idBrb1_var    % BRB V1変数ID配列
    idBrb2_var    % BRB V2変数ID配列
    idvar2srep    % 変数→代表断面 cell配列
  end

  properties (Dependent)
    % 派生マッピングプロパティ（動的に計算）
    idwfs2repwfs  % WFS断面→代表WFS断面 [nwfs×1]
    idhss2rephss  % HSS断面→代表HSS断面 [nhss×1]
    idbrbs2repbrbs % BRB断面→代表BRB断面 [nbrbs×1]
    idhsr2rephsr  % HSR断面→代表HSR断面 [nhsr×1]
    idrepwfs2wfs  % 代表WFS断面→WFS断面 [nrepwfs×1]
    idrephss2hss  % 代表HSS断面→HSS断面 [nrephss×1]
    idrepbrbs2brbs % 代表BRB断面→BRB断面 [nrepbrbs×1]
    idrephsr2hsr  % 代表HSR断面→HSR断面 [nrephsr×1]
    idrepwfs2var  % 代表WFS断面→変数 [nrepwfs×4]
    idrephss2var  % 代表HSS断面→変数 [nrephss×2]
    idrepbrbs2var % 代表BRB断面→変数 [nrepbrbs×2]
    idrephsr2var  % 代表HSR断面→変数 [nrephsr×2]

    % 断面リストマッピング
    idwfs2slist   % WFS断面→断面リストID [nwfs×1]
    idhss2slist   % HSS断面→断面リストID [nhss×1]
    idbrbs2slist  % BRB断面→断面リストID [nbrbs×1]
    idhsr2slist   % HSR断面→断面リストID [nhsr×1]
    idtbs2slist   % TB断面→断面リストID [ntbs×1]

    % 代表断面関連
    idsrep2stype  % 代表断面→断面タイプ [nsrep×1]
    idsrep2shape  % 代表断面→断面リストの鉄骨形状 [nsrep×1]

    % 断面タイプ変換マッピング
    idsec2wfs     % 断面→WFS断面 [nsec×1] (0:非WFS)
    idsec2hss     % 断面→HSS断面 [nsec×1] (0:非HSS)
    idsec2rcrs    % 断面→RCRS断面 [nsec×1] (0:非RCRS)
    idsec2brbs    % 断面→BRB断面 [nsec×1] (0:非BRB)
    idsec2hsr     % 断面→HSR断面 [nsec×1] (0:非HSR)

    % 逆変換マッピング
    idwfs2sec     % WFS断面→断面 [nwfs×1]
    idhss2sec     % HSS断面→断面 [nhss×1]
    idbrbs2sec    % BRB断面→断面 [nbrbs×1]
    idrcrs2sec    % RCRS断面→断面 [nrcrs×1]
    idhsr2sec     % HSR断面→断面 [nhsr×1]

    % RCRS代表断面マッピング
    idrcrs2reprcrs % RCRS断面→代表RCRS断面 [nrcrs×1]
    idreprcrs2rcrs % 代表RCRS断面→RCRS断面 [nreprcrs×1]

    % 代表断面個別マッピング
    idrepwfs2sec  % 代表WFS断面→断面 [nrepwfs×1]
    idrephss2sec  % 代表HSS断面→断面 [nrephss×1]
    idrepbrbs2sec % 代表BRB断面→断面 [nrepbrbs×1]
    idreprcrs2sec % 代表RCRS断面→断面 [nreprcrs×1]
    idrephsr2sec  % 代表HSR断面→断面 [nrephsr×1]

    % その他のマッピング
    idsrep2var    % 代表断面→変数 [nsrep×ndim]
    isVarofSlist  % 変数→断面リスト [nxvar×nlist] 論理配列
  end

  methods
    %% IdMapper
    function obj = IdMapper(idSectionList, idsec2stype, idsec2srep, ...
      idvar2vtype, idsrep2sec, idsec2var, idH2var, idB2var, idtw2var, ...
      idtf2var, idD2var, idt2var, idHsrD2var, idHsrt2var, idBrb1_var, ...
      idBrb2_var, idvar2srep, idsublistCell, idlist2stype)
      %IdMapper - 固定した断面・変数・断面リストの対応を保持する
      %   mapper = IdMapper(idSectionList, idsec2stype, ...
      %     idsec2srep, idvar2vtype, ...) は、
      %   ID変換・マッピング機能を提供するオブジェクトを作成します。
      %
      %   入力引数:
      %     idSectionList - 断面→断面リストIDマッピング [nsec×1] 整数配列
      %     idsec2stype - 断面→断面タイプマッピング [nsec×1] 整数配列
      %     idsec2srep - 断面→代表断面マッピング [nsec×1] 整数配列
      %     idvar2vtype - 変数→変数タイプマッピング [nxvar×1] 整数配列
      %     idsrep2sec - 代表断面→断面マッピング [nsrep×1] 整数配列
      %     idsec2var - 断面→変数マッピング [nsec×ndim] 整数配列
      %     idH2var - H変数ID配列（WFS断面）整数配列
      %     idB2var - B変数ID配列（WFS断面）整数配列
      %     idtw2var - tw変数ID配列（WFS断面）整数配列
      %     idtf2var - tf変数ID配列（WFS断面）整数配列
      %     idD2var - D変数ID配列（HSS断面）整数配列
      %     idt2var - t変数ID配列（HSS断面）整数配列
      %     idHsrD2var - D変数ID配列（HSR断面）整数配列
      %     idHsrt2var - t変数ID配列（HSR断面）整数配列
      %     idBrb1_var - BRB V1変数ID配列 整数配列
      %     idBrb2_var - BRB V2変数ID配列 整数配列
      %     idvar2srep - 変数→代表断面 cell配列
      %     idsublistCell - サブリストIDのcell配列 {nlist×1}
      %     idlist2stype - 断面リスト→鉄骨形状の種別 [nlist×1]
      %
      %   出力引数:
      %     obj - 固定した断面対応の管理オブジェクト
      %
      %   例:
      %     mapper = IdMapper(idSectionList, idsec2stype, ...
      %       idsec2srep, idvar2vtype, idsrep2sec, idsec2var, ...
      %       idH2var, idB2var, idtw2var, idtf2var, idD2var, idt2var, ...
      %       idHsrD2var, idHsrt2var, idBrb1_var, idBrb2_var, ...
      %       idvar2srep, ...
      %       idsublistCell, idlist2stype);

      if nargin ~= 19
        error('IdMapper:InvalidArguments', ...
          ['IdMapperは19個の引数が必要です' ...
           '（受け取った引数: %d個）'], nargin);
      end

      % 基本データの保存
      obj.idSectionList_ = idSectionList;
      obj.idsec2stype_ = idsec2stype;
      obj.idsec2srep_ = idsec2srep;
      obj.idvar2vtype_ = idvar2vtype;

      % 追加データの保存
      obj.idsrep2sec_ = idsrep2sec;
      obj.idsec2var_ = idsec2var;

      % 変数IDマッピングプロパティの保存
      obj.idH2var_ = idH2var;
      obj.idB2var_ = idB2var;
      obj.idtw2var_ = idtw2var;
      obj.idtf2var_ = idtf2var;
      obj.idD2var_ = idD2var;
      obj.idt2var_ = idt2var;
      obj.idHsrD2var_ = idHsrD2var;
      obj.idHsrt2var_ = idHsrt2var;
      obj.idBrb1_var_ = idBrb1_var;
      obj.idBrb2_var_ = idBrb2_var;
      obj.idvar2srep_ = idvar2srep;
      obj.idsublistCell = idsublistCell;

      % 候補写像の断面グループは、断面が参照する断面リストの種別で分ける。
      % 梁のWFSと柱のCWFS・CWFSIは同じH形鋼リストを使い、ブレース鋼材の
      % リストは読込み時にBWFS等へ書き戻されているため別グループになる。
      % 検定規則に使う利用種別 idsec2stype とは区別する
      idlist2stype = idlist2stype(:);
      has_list = idSectionList > 0;
      obj.idsec2shape_ = zeros(size(idSectionList));
      obj.idsec2shape_(has_list) = idlist2stype(idSectionList(has_list));

      % 代表断面から変数・断面種への派生マッピングを事前生成
      obj.initializeDerivedMappings();

      % 事前計算マッピングの生成
      % WFS断面マッピング
      isWfs = (obj.idsec2shape_ == PRM.WFS);
      if any(isWfs)
        [~, ia, ic] = unique(obj.idsec2srep_(isWfs));
        obj.idrepwfs2wfs_ = ia;  % 代表→最初のWFS断面
        obj.idwfs2repwfs_ = ic;  % WFS→代表
      else
        obj.idrepwfs2wfs_ = [];
        obj.idwfs2repwfs_ = [];
      end

      % HSS断面マッピング
      isHss = (obj.idsec2shape_ == PRM.HSS);
      if any(isHss)
        [~, ia, ic] = unique(obj.idsec2srep_(isHss));
        obj.idrephss2hss_ = ia;  % 代表→最初のHSS断面
        obj.idhss2rephss_ = ic;  % HSS→代表
      else
        obj.idrephss2hss_ = [];
        obj.idhss2rephss_ = [];
      end

      % BRB断面マッピング
      isBrbs = (obj.idsec2shape_ == PRM.BRB);
      if any(isBrbs)
        [~, ia, ic] = unique(obj.idsec2srep_(isBrbs));
        obj.idrepbrbs2brbs_ = ia;
        obj.idbrbs2repbrbs_ = ic;
      else
        obj.idrepbrbs2brbs_ = [];
        obj.idbrbs2repbrbs_ = [];
      end

      % HSR断面は全断面が代表断面
      nhsr_ = sum(obj.idsec2shape_ == PRM.HSR);
      obj.idhsr2rephsr_ = (1:nhsr_)';
      obj.idrephsr2hsr_ = (1:nhsr_)';

      % データ整合性検証
      obj.validateDataConsistency();
    end

    %% Dependentプロパティのゲッター
    function n = get.nsec(obj)
      %get.nsec - 総断面数を取得する
      %
      %   n = obj.nsec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - 総断面数
      n = length(obj.idsec2stype_);
    end

    function n = get.nwfs(obj)
      %get.nwfs - WFS断面数を取得する
      %
      %   n = obj.nwfs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - WFS断面数
      n = sum(obj.idsec2shape_ == PRM.WFS);
    end

    function n = get.nhss(obj)
      %get.nhss - HSS断面数を取得する
      %
      %   n = obj.nhss
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - HSS断面数
      n = sum(obj.idsec2shape_ == PRM.HSS);
    end

    function n = get.nrcrs(obj)
      %get.nrcrs - RCRS断面数を取得する
      %
      %   n = obj.nrcrs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - RCRS断面数
      n = sum(obj.idsec2stype_ == PRM.RCRS);
    end

    function n = get.nbrbs(obj)
      %get.nbrbs - BRB断面数を取得する
      %
      %   n = obj.nbrbs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - BRB断面数
      n = sum(obj.idsec2shape_ == PRM.BRB);
    end

    function n = get.nhsr(obj)
      %get.nhsr - HSR断面数を取得する
      %
      %   n = obj.nhsr
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - HSR断面数
      n = sum(obj.idsec2shape_ == PRM.HSR);
    end

    function n = get.nxvar(obj)
      %get.nxvar - 変数総数を取得する
      %
      %   n = obj.nxvar
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - 変数総数
      n = length(obj.idvar2vtype_);
    end

    function n = get.nsrep(obj)
      %get.nsrep - 代表断面数を取得する
      %
      %   n = obj.nsrep
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - 代表断面数
      n = length(obj.idsrep2sec_);
    end

    function n = get.nrepwfs(obj)
      %get.nrepwfs - 代表WFS断面数を取得する
      %
      %   n = obj.nrepwfs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - 代表WFS断面数
      n = length(obj.idrepwfs2wfs_);
    end

    function n = get.nrephss(obj)
      %get.nrephss - 代表HSS断面数を取得する
      %
      %   n = obj.nrephss
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - 代表HSS断面数
      n = length(obj.idrephss2hss_);
    end

    function n = get.nrepbrbs(obj)
      %get.nrepbrbs - 代表BRB断面数を取得する
      %
      %   n = obj.nrepbrbs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - 代表BRB断面数
      n = length(obj.idrepbrbs2brbs_);
    end

    function n = get.nrephsr(obj)
      %get.nrephsr - 代表HSR断面数を取得する
      %
      %   n = obj.nrephsr
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - 代表HSR断面数
      n = length(obj.idrephsr2hsr);
    end

    function n = get.nlist(obj)
      %get.nlist - 断面リスト数を取得する
      %
      %   n = obj.nlist
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     n - 断面リスト数
      n = length(obj.idsublistCell);
    end

    %% 基本データへの読み取り専用アクセス
    function val = get.idSectionList(obj)
      %get.idSectionList - 断面→断面リストIDを取得する
      %
      %   val = obj.idSectionList
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→断面リストID [nsec×1]（静的）
      val = obj.idSectionList_;
    end

    function val = get.idsec2stype(obj)
      %get.idsec2stype - 断面→断面タイプマッピングを取得する
      %
      %   val = obj.idsec2stype
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→断面タイプマッピング [nsec×1]
      val = obj.idsec2stype_;
    end

    function val = get.idsec2shape(obj)
      %get.idsec2shape - 断面→断面リストの鉄骨形状を取得する
      %
      %   val = obj.idsec2shape
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→断面リストの鉄骨形状 [nsec×1]（リストなしは0）
      val = obj.idsec2shape_;
    end

    function val = get.idsec2srep(obj)
      %get.idsec2srep - 断面→代表断面マッピングを取得する
      %
      %   val = obj.idsec2srep
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→代表断面マッピング [nsec×1]
      val = obj.idsec2srep_;
    end

    function val = get.idvar2vtype(obj)
      %get.idvar2vtype - 変数タイプマッピングを取得する
      %
      %   val = obj.idvar2vtype
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 変数タイプマッピング [nxvar×1]
      val = obj.idvar2vtype_;
    end

    function val = get.idsrep2sec(obj)
      %get.idsrep2sec - 代表断面→断面を取得する
      %
      %   val = obj.idsrep2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表断面→断面 [nsrep×1]
      val = obj.idsrep2sec_;
    end

    function val = get.idsec2var(obj)
      %get.idsec2var - 断面→変数を取得する
      %
      %   val = obj.idsec2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→変数 [nsec×ndim]
      val = obj.idsec2var_;
    end

    %% 変数IDマッピングプロパティのゲッター
    function val = get.idH2var(obj)
      %get.idH2var - H変数ID配列を取得する
      %
      %   val = obj.idH2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - H変数ID配列（WFS断面）
      val = obj.idH2var_;
    end

    function val = get.idB2var(obj)
      %get.idB2var - B変数ID配列を取得する
      %
      %   val = obj.idB2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - B変数ID配列（WFS断面）
      val = obj.idB2var_;
    end

    function val = get.idtw2var(obj)
      %get.idtw2var - tw変数ID配列を取得する
      %
      %   val = obj.idtw2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - tw変数ID配列（WFS断面）
      val = obj.idtw2var_;
    end

    function val = get.idtf2var(obj)
      %get.idtf2var - tf変数ID配列を取得する
      %
      %   val = obj.idtf2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - tf変数ID配列（WFS断面）
      val = obj.idtf2var_;
    end

    function val = get.idD2var(obj)
      %get.idD2var - D変数ID配列を取得する
      %
      %   val = obj.idD2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - D変数ID配列（HSS断面）
      val = obj.idD2var_;
    end

    function val = get.idt2var(obj)
      %get.idt2var - t変数ID配列を取得する
      %
      %   val = obj.idt2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - t変数ID配列（HSS断面）
      val = obj.idt2var_;
    end

    function val = get.idHsrD2var(obj)
      %get.idHsrD2var - HSR D変数ID配列を取得する
      %
      %   val = obj.idHsrD2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - HSR D変数ID配列（HSR断面）
      val = obj.idHsrD2var_;
    end

    function val = get.idHsrt2var(obj)
      %get.idHsrt2var - HSR t変数ID配列を取得する
      %
      %   val = obj.idHsrt2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - HSR t変数ID配列（HSR断面）
      val = obj.idHsrt2var_;
    end

    function val = get.idBrb1_var(obj)
      %get.idBrb1_var - BRB V1変数ID配列を取得する
      %
      %   val = obj.idBrb1_var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - BRB V1変数ID配列
      val = obj.idBrb1_var_;
    end

    function val = get.idBrb2_var(obj)
      %get.idBrb2_var - BRB V2変数ID配列を取得する
      %
      %   val = obj.idBrb2_var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - BRB V2変数ID配列
      val = obj.idBrb2_var_;
    end

    function val = get.idvar2srep(obj)
      %get.idvar2srep - 変数→代表断面を取得する
      %
      %   val = obj.idvar2srep
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 変数→代表断面 cell配列
      val = obj.idvar2srep_;
    end

    %% 派生マッピングプロパティのゲッター
    function val = get.idwfs2repwfs(obj)
      %get.idwfs2repwfs - WFS断面→代表WFS断面を取得する
      %
      %   val = obj.idwfs2repwfs
      %
      % コンストラクタで事前計算された値を返す
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - WFS断面→代表WFS断面 [nwfs×1]
      val = obj.idwfs2repwfs_;
    end

    function val = get.idhss2rephss(obj)
      %get.idhss2rephss - HSS断面→代表HSS断面を取得する
      %
      %   val = obj.idhss2rephss
      %
      % コンストラクタで事前計算された値を返す
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - HSS断面→代表HSS断面 [nhss×1]
      val = obj.idhss2rephss_;
    end

    function val = get.idrepwfs2wfs(obj)
      %get.idrepwfs2wfs - 代表WFS断面→WFS断面を取得する
      %
      %   val = obj.idrepwfs2wfs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表WFS断面→WFS断面 [nrepwfs×1]
      val = obj.idrepwfs2wfs_;
    end

    function val = get.idrephss2hss(obj)
      %get.idrephss2hss - 代表HSS断面→HSS断面を取得する
      %
      %   val = obj.idrephss2hss
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表HSS断面→HSS断面 [nrephss×1]
      val = obj.idrephss2hss_;
    end

    function val = get.idrepwfs2var(obj)
      %get.idrepwfs2var - 代表WFS断面→変数を取得する
      %
      %   val = obj.idrepwfs2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表WFS断面→変数 [nrepwfs×4]
      val = obj.idrepwfs2var_;
    end

    function val = get.idrephss2var(obj)
      %get.idrephss2var - 代表HSS断面→変数を取得する
      %
      %   val = obj.idrephss2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表HSS断面→変数 [nrephss×2]
      val = obj.idrephss2var_;
    end

    %% 断面リストマッピングのゲッター
    function val = get.idwfs2slist(obj)
      %get.idwfs2slist - WFS断面→断面リストIDを取得する
      %
      %   val = obj.idwfs2slist
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - WFS断面→断面リストID [nwfs×1]
      val = obj.idSectionList_(obj.idsec2shape_ == PRM.WFS);
      val = val(:);  % 列ベクトル化
    end

    function val = get.idhss2slist(obj)
      %get.idhss2slist - HSS断面→断面リストIDを取得する
      %
      %   val = obj.idhss2slist
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - HSS断面→断面リストID [nhss×1]
      val = obj.idSectionList_(obj.idsec2shape_ == PRM.HSS);
      val = val(:);  % 列ベクトル化
    end

    function val = get.idbrbs2slist(obj)
      %get.idbrbs2slist - BRB断面→断面リストIDを取得する
      %
      %   val = obj.idbrbs2slist
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - BRB断面→断面リストID [nbrbs×1]
      val = obj.idSectionList_(obj.idsec2shape_ == PRM.BRB);
      val = val(:);  % 列ベクトル化
    end

    function val = get.idhsr2slist(obj)
      %get.idhsr2slist - HSR断面→断面リストIDを取得する
      %
      %   val = obj.idhsr2slist
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - HSR断面→断面リストID [nhsr×1]
      val = obj.idSectionList_(obj.idsec2shape_ == PRM.HSR);
      val = val(:);  % 列ベクトル化
    end

    function val = get.idtbs2slist(obj)
      %get.idtbs2slist - TB断面→断面リストIDを取得する
      %
      %   val = obj.idtbs2slist
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - TB断面→断面リストID [ntbs×1]
      val = obj.idSectionList_(obj.idsec2shape_ == PRM.TB);
      val = val(:);  % 列ベクトル化
    end

    function val = get.idbrbs2repbrbs(obj)
      %get.idbrbs2repbrbs - BRB断面→代表BRB断面を取得する
      %
      %   val = obj.idbrbs2repbrbs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - BRB断面→代表BRB断面 [nbrbs×1]
      val = obj.idbrbs2repbrbs_;
    end

    function val = get.idrepbrbs2brbs(obj)
      %get.idrepbrbs2brbs - 代表BRB断面→BRB断面を取得する
      %
      %   val = obj.idrepbrbs2brbs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表BRB断面→BRB断面 [nrepbrbs×1]
      val = obj.idrepbrbs2brbs_;
    end

    function val = get.idrepbrbs2var(obj)
      %get.idrepbrbs2var - 代表BRB断面→変数を取得する
      %
      %   val = obj.idrepbrbs2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表BRB断面→変数 [nrepbrbs×2]
      val = obj.idrepbrbs2var_;
    end

    function val = get.idrephsr2hsr(obj)
      %get.idrephsr2hsr - 代表HSR断面→HSR断面を取得する
      %
      %   val = obj.idrephsr2hsr
      %
      % mapRepresentativeToHsrメソッドを呼び出す
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表HSR断面→HSR断面 [nrephsr×1]
      val = obj.mapRepresentativeToHsr();
    end

    function val = get.idhsr2rephsr(obj)
      %get.idhsr2rephsr - HSR断面→代表HSR断面を取得する
      %
      %   val = obj.idhsr2rephsr
      %
      % mapHsrToRepresentativeメソッドを呼び出す
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - HSR断面→代表HSR断面 [nhsr×1]
      val = obj.mapHsrToRepresentative();
    end

    function val = get.idrephsr2var(obj)
      %get.idrephsr2var - 代表HSR断面→変数を取得する
      %
      %   val = obj.idrephsr2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表HSR断面→変数 [nrephsr×2]
      val = obj.idrephsr2var_;
    end

    function val = get.idsrep2stype(obj)
      %get.idsrep2stype - 代表断面→断面タイプを取得する
      %
      %   val = obj.idsrep2stype
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表断面→断面タイプ [nsrep×1]
      val = obj.idsrep2stype_;
    end

    function val = get.idsrep2shape(obj)
      %get.idsrep2shape - 代表断面→断面リストの鉄骨形状を取得する
      %
      %   val = obj.idsrep2shape
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表断面→断面リストの鉄骨形状 [nsrep×1]
      val = obj.idsrep2shape_;
    end

    %% 断面タイプ変換マッピングのゲッター
    function val = get.idsec2wfs(obj)
      %get.idsec2wfs - 断面→WFS断面を取得する
      %
      %   val = obj.idsec2wfs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→WFS断面 [nsec×1] (0:非WFS)
      val = obj.mapSectionToWfs();
    end

    function val = get.idsec2hss(obj)
      %get.idsec2hss - 断面→HSS断面を取得する
      %
      %   val = obj.idsec2hss
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→HSS断面 [nsec×1] (0:非HSS)
      val = obj.mapSectionToHss();
    end

    function val = get.idsec2rcrs(obj)
      %get.idsec2rcrs - 断面→RCRS断面を取得する
      %
      %   val = obj.idsec2rcrs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→RCRS断面 [nsec×1] (0:非RCRS)
      val = obj.mapSectionToRcrs();
    end

    function val = get.idsec2brbs(obj)
      %get.idsec2brbs - 断面→BRB断面を取得する
      %
      %   val = obj.idsec2brbs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→BRB断面 [nsec×1] (0:非BRB)
      val = obj.mapSectionToBrbs();
    end

    function val = get.idsec2hsr(obj)
      %get.idsec2hsr - 断面→HSR断面を取得する
      %
      %   val = obj.idsec2hsr
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 断面→HSR断面 [nsec×1] (0:非HSR)
      val = obj.mapSectionToHsr();
    end

    %% 逆変換マッピングのゲッター
    function val = get.idwfs2sec(obj)
      %get.idwfs2sec - WFS断面→断面を取得する
      %
      %   val = obj.idwfs2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - WFS断面→断面 [nwfs×1]
      val = obj.mapWfsToSection();
    end

    function val = get.idhss2sec(obj)
      %get.idhss2sec - HSS断面→断面を取得する
      %
      %   val = obj.idhss2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - HSS断面→断面 [nhss×1]
      val = obj.mapHssToSection();
    end

    function val = get.idbrbs2sec(obj)
      %get.idbrbs2sec - BRB断面→断面を取得する
      %
      %   val = obj.idbrbs2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - BRB断面→断面 [nbrbs×1]
      val = obj.mapBrbsToSection();
    end

    function val = get.idrcrs2sec(obj)
      %get.idrcrs2sec - RCRS断面→断面を取得する
      %
      %   val = obj.idrcrs2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - RCRS断面→断面 [nrcrs×1]
      val = obj.mapRcrsToSection();
    end

    function val = get.idhsr2sec(obj)
      %get.idhsr2sec - HSR断面→断面を取得する
      %
      %   val = obj.idhsr2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - HSR断面→断面 [nhsr×1]
      val = obj.mapHsrToSection();
    end

    %% RCRS代表断面マッピングのゲッター
    function val = get.idrcrs2reprcrs(obj)
      %get.idrcrs2reprcrs - RCRS断面→代表RCRS断面を取得する
      %
      %   val = obj.idrcrs2reprcrs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - RCRS断面→代表RCRS断面 [nrcrs×1]
      val = obj.mapRcrsToRepresentative();
    end

    function val = get.idreprcrs2rcrs(obj)
      %get.idreprcrs2rcrs - 代表RCRS断面→RCRS断面を取得する
      %
      %   val = obj.idreprcrs2rcrs
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表RCRS断面→RCRS断面 [nreprcrs×1]
      val = obj.mapRepresentativeToRcrs();
    end

    %% 代表断面個別マッピングのゲッター
    function val = get.idrepwfs2sec(obj)
      %get.idrepwfs2sec - 代表WFS断面→断面を取得する
      %
      %   val = obj.idrepwfs2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表WFS断面→断面 [nrepwfs×1]
      val = obj.mapRepresentativeWfsToSection();
    end

    function val = get.idrephss2sec(obj)
      %get.idrephss2sec - 代表HSS断面→断面を取得する
      %
      %   val = obj.idrephss2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表HSS断面→断面 [nrephss×1]
      val = obj.mapRepresentativeHssToSection();
    end

    function val = get.idrepbrbs2sec(obj)
      %get.idrepbrbs2sec - 代表BRB断面→断面を取得する
      %
      %   val = obj.idrepbrbs2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表BRB断面→断面 [nrepbrbs×1]
      val = obj.mapRepresentativeBrbsToSection();
    end

    function val = get.idreprcrs2sec(obj)
      %get.idreprcrs2sec - 代表RCRS断面→断面を取得する
      %
      %   val = obj.idreprcrs2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表RCRS断面→断面 [nreprcrs×1]
      val = obj.mapRepresentativeRcrsToSection();
    end

    function val = get.idrephsr2sec(obj)
      %get.idrephsr2sec - 代表HSR断面→断面を取得する
      %
      %   val = obj.idrephsr2sec
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表HSR断面→断面 [nrephsr×1]
      val = find(obj.idsec2shape_ == PRM.HSR);
    end

    %% その他のマッピングのゲッター
    function val = get.idsrep2var(obj)
      %get.idsrep2var - 代表断面→変数を取得する
      %
      %   val = obj.idsrep2var
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 代表断面→変数 [nsrep×ndim]
      val = obj.idsrep2var_;
    end

    function val = get.isVarofSlist(obj)
      %get.isVarofSlist - 変数-断面リストマッピングを取得する
      %
      %   val = obj.isVarofSlist
      %
      %   入力引数:
      %     obj - IdMapper オブジェクト
      %
      %   出力引数:
      %     val - 変数-断面リストマッピング [nxvar×nlist]
      val = obj.getIsVarofSlist();
    end
  end

  methods (Access = private)
    initializeDerivedMappings(obj) % 派生マッピングを事前生成
    validateDataConsistency(obj)  % 外部ファイルに定義
  end
end
