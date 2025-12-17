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
  %     nme - 部材数
  %     nxvar - 変数数
  %     idSectionList - 断面→断面リストIDマッピング [nsec×1]
  %     idsec2stype - 断面→断面タイプマッピング [nsec×1]
  %     idsec2srep - 断面→代表断面マッピング [nsec×1]
  %     idme2sec - 部材→断面マッピング [nme×1]
  %     idvar2vtype - 変数→変数タイプマッピング [nxvar×1]
  %
  %   IdMapper メソッド:
  %     lookupSectionType - 断面→断面タイプ参照
  %     lookupVariableType - 変数→変数タイプ参照
  %     mapSectionToWfs - 断面→WFS断面変換
  %     mapSectionToHss - 断面→HSS断面変換
  %     mapWfsToSection - WFS断面→断面変換
  %     mapHssToSection - HSS断面→断面変換
  %     mapMemberToSection - 部材→断面変換
  %
  %   例:
  %     mapper = IdMapper(idSectionList, idsec2stype, ...
  %       idsec2srep, idme2sec, idvar2vtype);
  %     idwfs = mapper.mapSectionToWfs(5);
  %
  %   参考:
  %     SectionConstraintValidator, SectionManager
  
  properties (Access = private)
    % 基本的なマッピング配列（外部から提供）
    idSectionList_ % 断面→断面リストID [nsec×1]（静的）
    idsec2stype_   % 断面→断面タイプ [nsec×1]
    idsec2srep_    % 断面→代表断面 [nsec×1]
    idme2sec_      % 部材→断面 [nme×1]
    idvar2vtype_   % 変数→変数タイプ [nxvar×1]

    % 事前計算されたマッピング（コンストラクタで計算）
    idwfs2repwfs_  % WFS断面→代表WFS断面 [nwfs×1]
    idrepwfs2wfs_  % 代表WFS→最初のWFS断面 [nrepwfs×1]
    idhss2rephss_  % HSS断面→代表HSS断面 [nhss×1]
    idrephss2hss_  % 代表HSS→最初のHSS断面 [nrephss×1]
    idhsr2rephsr_  % HSR断面→代表HSR断面 [nhsr×1]
    idrephsr2hsr_  % 代表HSR→最初のHSR断面 [nrephsr×1]
    idsrep2sec_    % 代表断面→断面 [nsrep×1]
    idsec2var_     % 断面→変数 [nsec×ndim]

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
    idme2mtype_    % 部材→部材タイプ [nme×1]
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
    nme           % 部材数
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
    idsec2srep    % 断面→代表断面 [nsec×1]
    idme2sec      % 部材→断面 [nme×1]
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
    idme2mtype    % 部材→部材タイプ [nme×1]
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
    
    % 部材関連マッピング
    idme2stype    % 部材→断面タイプ [nme×1]
    idme2var      % 部材→変数 [nme×nxvar]
    
    % 断面リストマッピング
    idwfs2slist   % WFS断面→断面リストID [nwfs×1]
    idhss2slist   % HSS断面→断面リストID [nhss×1]
    idbrbs2slist  % BRB断面→断面リストID [nbrbs×1]
    idhsr2slist   % HSR断面→断面リストID [nhsr×1]
    
    % 代表断面関連
    idsrep2stype  % 代表断面→断面タイプ [nsrep×1]
    
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
    function obj = IdMapper(idSectionList, idsec2stype, ...
        idsec2srep, idme2sec, idvar2vtype, idsrep2sec, idsec2var, ...
        idH2var, idB2var, idtw2var, idtf2var, idD2var, idt2var, ...
        idHsrD2var, idHsrt2var, idBrb1_var, idBrb2_var, idme2mtype, idvar2srep, ...
        idsublistCell)
      %IdMapper コンストラクタ
      %   mapper = IdMapper(idSectionList, idsec2stype, ...
      %     idsec2srep, idme2sec, idvar2vtype, ...) は、
      %   ID変換・マッピング機能を提供するオブジェクトを作成します。
      %
      %   入力引数:
      %     idSectionList - 断面→断面リストIDマッピング [nsec×1] 整数配列
      %     idsec2stype - 断面→断面タイプマッピング [nsec×1] 整数配列
      %     idsec2srep - 断面→代表断面マッピング [nsec×1] 整数配列
      %     idme2sec - 部材→断面マッピング [nme×1] 整数配列
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
      %     idme2mtype - 部材→部材タイプ [nme×1] 整数配列
      %     idvar2srep - 変数→代表断面 cell配列
      %     idsublistCell - サブリストIDのcell配列 {nlist×1}
      %
      %   例:
      %     mapper = IdMapper(idSectionList, idsec2stype, ...
      %       idsec2srep, idme2sec, idvar2vtype, idsrep2sec, idsec2var, ...
      %       idH2var, idB2var, idtw2var, idtf2var, idD2var, idt2var, ...
      %       idHsrD2var, idHsrt2var, idBrb1_var, idBrb2_var, idme2mtype, idvar2srep, ...
      %       idsublistCell);

      if nargin ~= 20
        error('IdMapper:InvalidArguments', ...
          'IdMapperは20個の引数が必要です（受け取った引数: %d個）', nargin);
      end
      
      % 基本データの保存
      obj.idSectionList_ = idSectionList;
      obj.idsec2stype_ = idsec2stype;
      obj.idsec2srep_ = idsec2srep;
      obj.idme2sec_ = idme2sec;
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
      obj.idme2mtype_ = idme2mtype;
      obj.idvar2srep_ = idvar2srep;
      obj.idsublistCell = idsublistCell;  % サブリストIDデータの保存

      % 事前計算マッピングの生成
      % WFS断面マッピング
      isWfs = (obj.idsec2stype_ == PRM.WFS);
      if any(isWfs)
        [~, ia, ic] = unique(obj.idsec2srep_(isWfs));
        obj.idrepwfs2wfs_ = ia;  % 代表→最初のWFS断面
        obj.idwfs2repwfs_ = ic;  % WFS→代表
      else
        obj.idrepwfs2wfs_ = [];
        obj.idwfs2repwfs_ = [];
      end
      
      % HSS断面マッピング
      isHss = (obj.idsec2stype_ == PRM.HSS);
      if any(isHss)
        [~, ia, ic] = unique(obj.idsec2srep_(isHss));
        obj.idrephss2hss_ = ia;  % 代表→最初のHSS断面
        obj.idhss2rephss_ = ic;  % HSS→代表
      else
        obj.idrephss2hss_ = [];
        obj.idhss2rephss_ = [];
      end
      
      % データ整合性検証
      obj.validateDataConsistency();
    end
    
    %% Dependentプロパティのゲッター
    function n = get.nsec(obj)
      n = length(obj.idsec2stype_);
    end
    
    function n = get.nwfs(obj)
      n = sum(obj.idsec2stype_ == PRM.WFS);
    end
    
    function n = get.nhss(obj)
      n = sum(obj.idsec2stype_ == PRM.HSS);
    end
    
    function n = get.nrcrs(obj)
      n = sum(obj.idsec2stype_ == PRM.RCRS);
    end
    
    function n = get.nbrbs(obj)
      n = sum(obj.idsec2stype_ == PRM.BRB);
    end

    function n = get.nhsr(obj)
      n = sum(obj.idsec2stype_ == PRM.HSR);
    end

    function n = get.nme(obj)
      n = length(obj.idme2sec_);
    end
    
    function n = get.nxvar(obj)
      n = length(obj.idvar2vtype_);
    end
    
    function n = get.nsrep(obj)
      n = length(obj.idsrep2sec_);
    end
    
    function n = get.nrepwfs(obj)
      % 代表WFS断面数を計算
      n = length(obj.idrepwfs2wfs_);
    end
    
    function n = get.nrephss(obj)
      % 代表HSS断面数を計算
      n = length(obj.idrephss2hss_);
    end
    
    function n = get.nrepbrbs(obj)
      % 代表BRB断面数を計算
      n = length(obj.idrepbrbs2brbs);
    end

    function n = get.nrephsr(obj)
      % 代表HSR断面数を計算
      n = length(obj.idrephsr2hsr);
    end
    
    function n = get.nlist(obj)
      % 断面リスト数を計算
      n = max(obj.idSectionList_);
    end
    
    %% 基本データへの読み取り専用アクセス
    function val = get.idSectionList(obj)
      val = obj.idSectionList_;
    end
    
    function val = get.idsec2stype(obj)
      val = obj.idsec2stype_;
    end
    
    function val = get.idsec2srep(obj)
      val = obj.idsec2srep_;
    end
    
    function val = get.idme2sec(obj)
      val = obj.idme2sec_;
    end
    
    function val = get.idvar2vtype(obj)
      val = obj.idvar2vtype_;
    end
    
    function val = get.idsrep2sec(obj)
      val = obj.idsrep2sec_;
    end
    
    function val = get.idsec2var(obj)
      val = obj.idsec2var_;
    end
    
    %% 変数IDマッピングプロパティのゲッター
    function val = get.idH2var(obj)
      val = obj.idH2var_;
    end
    
    function val = get.idB2var(obj)
      val = obj.idB2var_;
    end
    
    function val = get.idtw2var(obj)
      val = obj.idtw2var_;
    end
    
    function val = get.idtf2var(obj)
      val = obj.idtf2var_;
    end
    
    function val = get.idD2var(obj)
      val = obj.idD2var_;
    end
    
    function val = get.idt2var(obj)
      val = obj.idt2var_;
    end

    function val = get.idHsrD2var(obj)
      val = obj.idHsrD2var_;
    end

    function val = get.idHsrt2var(obj)
      val = obj.idHsrt2var_;
    end

    function val = get.idBrb1_var(obj)
      val = obj.idBrb1_var_;
    end
    
    function val = get.idBrb2_var(obj)
      val = obj.idBrb2_var_;
    end
    
    function val = get.idme2mtype(obj)
      val = obj.idme2mtype_;
    end
    
    function val = get.idvar2srep(obj)
      val = obj.idvar2srep_;
    end
    
    %% 派生マッピングプロパティのゲッター
    function val = get.idwfs2repwfs(obj)
      % WFS断面→代表WFS断面マッピング配列を取得
      % コンストラクタで事前計算された値を返す
      val = obj.idwfs2repwfs_;
    end
    
    function val = get.idhss2rephss(obj)
      % HSS断面→代表HSS断面マッピング配列を取得
      % コンストラクタで事前計算された値を返す
      val = obj.idhss2rephss_;
    end
    
    function val = get.idrepwfs2wfs(obj)
      % 代表WFS断面→WFS断面配列を取得
      % mapRepresentativeToWfsメソッドを呼び出す
      val = obj.mapRepresentativeToWfs();
    end
    
    function val = get.idrephss2hss(obj)
      % 代表HSS断面→HSS断面配列を取得
      % mapRepresentativeToHssメソッドを呼び出す
      val = obj.mapRepresentativeToHss();
    end
    
    function val = get.idrepwfs2var(obj)
      % 代表WFS断面→変数マッピングを取得
      % mapRepresentativeWfsToVariableメソッドを呼び出す
      val = obj.mapRepresentativeWfsToVariable();
    end
    
    function val = get.idrephss2var(obj)
      % 代表HSS断面→変数マッピングを取得
      % mapRepresentativeHssToVariableメソッドを呼び出す
      val = obj.mapRepresentativeHssToVariable();
    end
    
    %% 断面リストマッピングのゲッター
    function val = get.idwfs2slist(obj)
      % WFS断面の断面リストIDを取得
      val = obj.idSectionList_(obj.idsec2stype_ == PRM.WFS);
      val = val(:);  % 列ベクトル化
    end
    
    function val = get.idhss2slist(obj)
      % HSS断面の断面リストIDを取得
      val = obj.idSectionList_(obj.idsec2stype_ == PRM.HSS);
      val = val(:);  % 列ベクトル化
    end
    
    function val = get.idbrbs2slist(obj)
      % BRB断面の断面リストIDを取得
      val = obj.idSectionList_(obj.idsec2stype_ == PRM.BRB);
      val = val(:);  % 列ベクトル化
    end

    function val = get.idhsr2slist(obj)
      % HSR断面の断面リストIDを取得
      val = obj.idSectionList_(obj.idsec2stype_ == PRM.HSR);
      val = val(:);  % 列ベクトル化
    end
    
    function val = get.idbrbs2repbrbs(obj)
      % BRB断面→代表BRB断面マッピングを取得
      % mapBrbsToRepresentativeメソッドを呼び出す
      val = obj.mapBrbsToRepresentative();
    end
    
    function val = get.idrepbrbs2brbs(obj)
      % 代表BRB断面→BRB断面マッピングを取得
      % mapRepresentativeToBrbsメソッドを呼び出す
      val = obj.mapRepresentativeToBrbs();
    end
    
    function val = get.idrepbrbs2var(obj)
      % 代表BRB断面→変数マッピングを取得
      % mapRepresentativeBrbsToVariableメソッドを呼び出す
      val = obj.mapRepresentativeBrbsToVariable();
    end

    function val = get.idrephsr2hsr(obj)
      % 代表HSR断面→HSR断面マッピングを取得
      % mapRepresentativeToHsrメソッドを呼び出す
      val = obj.mapRepresentativeToHsr();
    end

    function val = get.idhsr2rephsr(obj)
      % HSR断面→代表HSR断面マッピングを取得
      % mapHsrToRepresentativeメソッドを呼び出す
      val = obj.mapHsrToRepresentative();
    end

    function val = get.idrephsr2var(obj)
      % 代表HSR断面→変数マッピングを取得
      % mapRepresentativeHsrToVariableメソッドを呼び出す
      val = obj.mapRepresentativeHsrToVariable();
    end

    function val = get.idme2var(obj)
      % 部材→変数マッピングを取得
      % idsec2varとidme2secから計算
      val = obj.idsec2var(obj.idme2sec, :);
    end
    
    function val = get.idsrep2stype(obj)
      % 代表断面→断面タイプマッピングを取得
      % mapRepresentativeToSectionTypeメソッドを呼び出す
      val = obj.mapRepresentativeToSectionType();
    end
    
    %% 断面タイプ変換マッピングのゲッター
    function val = get.idsec2wfs(obj)
      % 断面→WFS断面マッピングを取得
      val = obj.mapSectionToWfs();
    end
    
    function val = get.idsec2hss(obj)
      % 断面→HSS断面マッピングを取得
      val = obj.mapSectionToHss();
    end
    
    function val = get.idsec2rcrs(obj)
      % 断面→RCRS断面マッピングを取得
      val = obj.mapSectionToRcrs();
    end
    
    function val = get.idsec2brbs(obj)
      % 断面→BRB断面マッピングを取得
      val = obj.mapSectionToBrbs();
    end

    function val = get.idsec2hsr(obj)
      % 断面→HSR断面マッピングを取得
      val = obj.mapSectionToHsr();
    end

    %% 逆変換マッピングのゲッター
    function val = get.idwfs2sec(obj)
      % WFS断面→断面マッピングを取得
      val = obj.mapWfsToSection();
    end
    
    function val = get.idhss2sec(obj)
      % HSS断面→断面マッピングを取得
      val = obj.mapHssToSection();
    end
    
    function val = get.idbrbs2sec(obj)
      % BRB断面→断面マッピングを取得
      val = obj.mapBrbsToSection();
    end
    
    function val = get.idrcrs2sec(obj)
      % RCRS断面→断面マッピングを取得
      val = obj.mapRcrsToSection();
    end

    function val = get.idhsr2sec(obj)
      % HSR断面→断面マッピングを取得
      val = obj.mapHsrToSection();
    end
    
    %% RCRS代表断面マッピングのゲッター
    function val = get.idrcrs2reprcrs(obj)
      % RCRS断面→代表RCRS断面マッピングを取得
      val = obj.mapRcrsToRepresentative();
    end
    
    function val = get.idreprcrs2rcrs(obj)
      % 代表RCRS断面→RCRS断面リストを取得
      val = obj.mapRepresentativeToRcrs();
    end
    
    %% 代表断面個別マッピングのゲッター
    function val = get.idrepwfs2sec(obj)
      % 代表WFS断面→断面マッピングを取得
      val = obj.mapRepresentativeWfsToSection();
    end
    
    function val = get.idrephss2sec(obj)
      % 代表HSS断面→断面マッピングを取得
      val = obj.mapRepresentativeHssToSection();
    end
    
    function val = get.idrepbrbs2sec(obj)
      % 代表BRB断面→断面マッピングを取得
      val = obj.mapRepresentativeBrbsToSection();
    end
    
    function val = get.idreprcrs2sec(obj)
      % 代表RCRS断面→断面マッピングを取得
      val = obj.mapRepresentativeRcrsToSection();
    end

    function val = get.idrephsr2sec(obj)
      % 代表HSR断面→断面マッピングを取得
      isHsr = (obj.idsec2stype_ == PRM.HSR);
      val = find(isHsr);
    end
    
    %% その他のマッピングのゲッター
    function val = get.idsrep2var(obj)
      % 代表断面→変数マッピングを取得
      val = obj.mapRepresentativeToVariable();
    end
    
    function val = get.idme2stype(obj)
      % 部材→断面タイプマッピングを取得
      val = obj.mapMemberToSectionType();
    end
    
    function val = get.isVarofSlist(obj)
      % 変数→断面リストマッピングを取得
      val = obj.getIsVarofSlist();
    end
  end
  
  methods (Access = private)
    validateDataConsistency(obj)  % 外部ファイルに定義
  end
end