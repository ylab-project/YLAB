classdef PRM
  % PRM プロジェクト共通パラメータ定義
  %
  % YLABシステム全体で使用される定数・パラメータを定義する。
  % 断面種別、部材種別、物理定数、終了コード等を一元管理。
  %
  % Example:
  %   if sectionType == PRM.WFS
  %     % H形鋼の処理
  %   end
  %
  % See also: SectionManager, SectionPropertyCalculator
  
  properties(Constant)
    %% 入力ブロック定義
    DATA_DEFINITIONS = { ...
      '基本事項', ''; ...
      '構造計算条件', ''; ...
      '最適化条件', ''; ...
      '制約条件', ''; ...
      '出力制御', ''; ...
      '材料', ''; ...
      '断面リスト', ''; ...
      '柱脚リスト', ''; ...
      '軸X', ''; ...
      '軸Y', ''; ...
      '層', ''; ...
      'スパンX方向', ''; ...
      'スパンY方向', ''; ...
      '階', ''; ...
      '標準階高と梁心の差', ''; ...
      '剛床仮定の解除', ''; ...
      '節点', ''; ...
      '支点', ''; ...
      '部材の寄り', ''; ...
      '柱の寄り', ''; ...
      '大梁の寄り', ''; ...
      '軸振れ', ''; ...
      'セットバック', ''; ...
      '大梁のレベル調整', ''; ...
      '節点の同一化', ''; ...
      '設計変数', ''; ...
      '梁せい分布除外', ''; ...
      '柱外径差制限の除外', ''; ...
      'S梁断面', ''; ...
      'S柱断面', ''; ...
      'RC梁断面', ''; ...
      'RC柱断面', ''; ...
      'メーカー製柱脚断面', ''; ...
      '鉛直ブレース断面（鋼材）', ''; ...
      '鉛直ブレース断面（メーカー製品）', ''; ...
      '鉛直ブレース断面（引張ブレース）', ''; ...
      '水平ブレース断面', ''; ...
      'S梁断面(仮定)', ''; ...
      'S柱断面(仮定)', ''; ...
      '鉛直ブレース断面（鋼材）(仮定)', ''; ...
      '鉛直ブレース断面（メーカー製品）(仮定)', ''; ...
      '大梁配置', ''; ...
      '柱配置', ''; ...
      '鉛直ブレース配置', ''; ...
      '水平ブレース配置', ''; ...
      '梁の結合状態', ''; ...
      '柱の結合状態', ''; ...
      '柱の剛域', ''; ...
      '梁の横補剛', ''; ...
      '柱の座屈長さ係数', ''; ...
      '通し柱', ''; ...
      '通し梁', ''; ...
      'スラブ協力幅', ''; ...
      '柱の剛度増減率', ''; ...
      '梁の剛度増減率', 'CCCCCCCDD'; ...
      '梁の捩り剛性増減率', ''; ...
      '柱の捩り剛性増減率', ''; ...
      '断面算定の省略（梁符号毎）', ''; ...
      '断面算定の省略（柱符号毎）', ''; ...
      '荷重ケース', ''; ...
      '節点荷重', ''; ...
      '地震力作用位置の直接入力', ''; ...
      '追加節点荷重', ''; ...
      '梁要素荷重', ''; ...
      }

    %% 座標・方向
    X = 1;                % X方向
    Y = 2;                % Y方向  
    Z = 3;                % Z方向
    XY = 12;              % XY方向(45度方向)
    TOL_DIR = 0.01;       % 方向判定用許容差
    TOL_FORCE_N = 1000;   % 力・軸力判定用許容差 [N]
    TOL_STIFF_UNSTABLE = 1e-6  % 不安定自由度判定用剛性許容差

    %% 節点種別
    SUPPORT = 100         % 支点節点

    %% 鋼種
    GRADE_SS = 1
    GRADE_SN = 2
    GRADE_SM = 3

    %% 部材種別
    COLUMN = 1            % 柱
    GIRDER = 2            % 梁
    BRACE  = 3            % ブレース
    HORIZONTAL_BRACE = 4  % 水平ブレース

    %% 名目部材種別
    NOMINAL_MULTI_MEMBER = 100
    NOMINAL_MULTI_COLUMN_BRACE = 101
    NOMINAL_MULTI_GIRDER_BRACE = 102
    NOMINAL_NORMAL_MEMBER = 0

    % 断面種別（梁/柱）
    WFS  = 10   % Ｈ形鋼
    HSS  = 20   % 角形鋼管
    HSR  = 30   % 円形鋼管
    RCRS = 50   % ＲＣ矩形断面
    % 断面種別（ブレース鋼材）
    BWFS = 11   % ブレースＨ形鋼
    BHSS = 21   % ブレース角形鋼管
    BHSR = 31   % ブレース円形鋼管
    BRB  = 101  % 座屈拘束ブレース
    HBR  = 110  % 水平ブレース
    TB   = 120  % 引張ブレース
    OTS  = 999  % その他

    % 柱脚
    CB_DIRECT = 71 % 柱脚：剛性指定
    CB_LIST = 72 % 柱脚：柱脚リスト

    % 変数種別番号
    MAX_NVAR = 1000; % 最大変数次元
    MAX_NSVAR = 4;  % 1断面の最大変数次元

    %% H形鋼変数
    WFS_H = 201           % せい(H)
    WFS_B = 202           % 幅(B)
    WFS_TW = 203          % ウェブ厚(tw)
    WFS_TF = 204          % フランジ厚(tf)

    %% 角形鋼管変数
    HSS_D = 205           % 外径(D)
    HSS_T = 206           % 板厚(t)

    %% 円形鋼管変数
    HSR_D = 207           % 外径(D)
    HSR_T = 208           % 板厚(t)

    %% 座屈拘束ブレース変数
    % UBBの場合: V1=タイプ, V2=降伏軸力, V3=枝番, V4=新旧番号
    BRB_V1 = 301          % タイプ
    BRB_V2 = 302          % 降伏軸力
    BRB_V3 = 303          % 枝番
    BRB_V4 = 304          % 新旧番号

    %% 引張ブレース形状コード
    TB_L   = 1211         % 山形鋼
    TB_2L  = 1212         % 2山形鋼
    TB_2LP = 1213         % 2山形鋼（並列）
    TB_C   = 1221         % 溝形鋼
    TB_2C  = 1222         % 2溝形鋼
    TB_TB  = 1231         % ターンバックル
    TB_FB  = 1241         % 平鋼

    %% secdim配列の列インデックス（WFS断面用）
    % WFS断面のsecdim配列は7列構成
    SECDIM_WFS_H = 1      % H実寸法
    SECDIM_WFS_B = 2      % B実寸法
    SECDIM_WFS_TW = 3     % tw実寸法
    SECDIM_WFS_TF = 4     % tf実寸法
    SECDIM_WFS_H_NOM = 6  % H公称値（nominal）
    SECDIM_WFS_B_NOM = 7  % B公称値（nominal）
    
    %% secdim配列の列インデックス（HSS断面用）
    SECDIM_HSS_D = 1      % D実寸法
    SECDIM_HSS_T = 2      % t実寸法
    
    %% secdim配列の列インデックス（HSR断面用）
    SECDIM_HSR_D = 1      % D実寸法
    SECDIM_HSR_T = 2      % t実寸法
    
    %% secdim配列の列インデックス（BRB断面用）
    SECDIM_BRB_V1 = 1     % V1値
    SECDIM_BRB_V2 = 2     % V2値
    
    %% 断面リストデータの列インデックス（BRB断面用）
    % getSectionDimensionで取得される断面リストのBRBデータ構造
    SECLIST_BRB_PRODUCT = 1    % 製品番号（101400=UB400, 101490=UB490）
    SECLIST_BRB_NY = 2         % 降伏軸力 [tonf]
    SECLIST_BRB_SUBTYPE = 3    % サブ番号（1,2,3等）
    SECLIST_BRB_WEIGHT = 4     % 単位重量 [N/mm]
    
    %% 変数タイプセット（境界値計算用）
    VTYPE_SET_BOUNDS = [PRM.WFS_H PRM.WFS_B ...
      PRM.WFS_TW PRM.WFS_TF PRM.HSS_D PRM.HSS_T ...
      PRM.HSR_D PRM.HSR_T PRM.BRB_V1 PRM.BRB_V2];

    %% UB種別
    UB400 = 101400
    UB490 = 101490
    
    %% ブレース種別
    BRACE_TENSION = 1001              % 引張のみ
    BRACE_TENSION_COMPRESSION = 1002  % 引張圧縮

    %% 物理定数
    GRAVITY = 9.80665     % 標準重力加速度 [m/s2]
    RHOS = 7.85           % 鋼材密度 [t/m3]
    ES   = 205000         % 鋼材ヤング係数 [N/mm2]
    RHORC = 2.5           % RC密度 [t/m3]（24.5 kN/m3）
    MAX_SECTION_LIST = 4;

    %% 剛性低減係数
    % 剛性組立で「剛性 0」相当を表現する微小値（完全 0 は数値問題）
    STIFF_IGNORE_FACTOR = 1e-6

    %% 荷重ケース
    LT = 1                % G+P (長期荷重)
    EXP = 2               % L+Ex (X方向正)
    EXN = 3               % L-Ex (X方向負)
    EYP = 4               % L+Ey (Y方向正)
    EYN = 5               % L-Ey (Y方向負)

    %% スラブ合成効果
    COMPOSITE_SLAB_NONE = 0    % 合成効果なし
    COMPOSITE_SLAB_WIDTH = 1   % 幅指定
    COMPOSITE_SLAB_DIRECT = 2  % 直接指定

    %% RC柱・梁Aの計算方法
    RC_AREA_FLOOR_WALL = 1    % 床と腰壁・垂壁を考慮
    RC_AREA_WALL_ONLY = 2     % 腰壁・垂壁を考慮（SS7初期値）
    RC_AREA_SECTION_ONLY = 3  % 部材断面のみ

    %% ブレース取付位置
    BRACE_FOUNDATION_GIRDER_TOP = 1     % 梁上端
    BRACE_FOUNDATION_GIRDER_CENTER = 2  % 梁中心

    %% S梁の軸力を考慮した検定（SS7マニュアル 2.5.4 準拠）
    S_GIRDER_AXIAL_NONE = 1   % しない
    S_GIRDER_AXIAL_ALL  = 2   % する（すべて）
    S_GIRDER_AXIAL_AUTO = 3   % する（軸力が生じた梁のみ）(初期値)

    %% 梁水平面内変形の考慮（SS7マニュアル 2.3 応力計算条件 準拠）
    GIRDER_HSTIFF_ZERO = 1    % 剛性を0とする（微小化）(初期値)
    GIRDER_HSTIFF_ACTUAL = 2  % 原断面の剛性を考慮（Iz=Izo, Asy=Asyo）
    GIRDER_HSTIFF_RIGID = 3   % 変形しない（Iz=Iy×1000, Asy=∞）

    %% ペナルティ指標
    PENALTY_SUM_TOTAL = 0     % 総和
    PENALTY_MAXIMUM = 1       % 最大値

    %% 梁せい平滑化
    GIRDER_HEIGHT_SMOOTH_MAX = 0   % 最大値ベース
    GIRDER_HEIGHT_SMOOTH_AXIS = 1  % 軸ベース

    %% 結合状態
    PIN = 0               % ピン結合
    FIX = 1               % 剛結合

    %% 保有耐力横補剛
    STIFFNING_EVENLY_DISTRIBUTTION = 1  % 等間隔配置
    STIFFNING_END_DISTRIBUTTION = 2     % 端部配置

    %% 保有耐力接合（仕口）
    JBS_STANDARD = 1  % 基準解説書式
    JBS_AIJ      = 2  % 鋼構造接合部設計指針式

    %% 設計ルート
    ROUTE_1   = 1     % ルート1
    ROUTE_2_1 = 21    % ルート2-1
    ROUTE_2_2 = 22    % ルート2-2
    ROUTE_3   = 3     % ルート3（保有水平耐力計算）

    %% 節点種類
    NODE_STANDARD = 0         % 標準節点
    NODE_FLEX_DIAPHRAGM = 10  % 柔床節点
    NODE_BRACE_FOR_GIRDER = 98  % ブレース用梁分割節点
    NODE_BRACE_FOR_COLUMN = 99  % ブレース用柱分割節点
    NODE_ABSORBED = 100       % 節点同一化で他節点へ吸収済み（無効節点）
    
    %% 梁種類
    GIRDER_STANDARD = 0       % 標準梁
    GIRDER_FOR_KBRACE1 = 96   % K形ブレース梁1（左側）
    GIRDER_FOR_KBRACE2 = 97   % K形ブレース梁2（右側）

    %% 柱種類
    COLUMN_STANDARD = 0       % 標準柱
    COLUMN_FOR_BRACE_FOUNDATION = 98  % ブレース柱（下側）
    COLUMN_FOR_BRACE_BODY = 99        % ブレース柱（上側）

    %% 部材群種別
    COLUMN_RANK_FA = 1        % 柱FAランク
    COLUMN_RANK_FB = 2        % 柱FBランク
    COLUMN_RANK_FC = 3        % 柱FCランク
    COLUMN_RANK_FD = 4        % 柱FDランク
    GIRDER_RANK_FA = 1        % 梁FAランク
    GIRDER_RANK_FB = 2        % 梁FBランク
    GIRDER_RANK_FC = 3        % 梁FCランク
    GIRDER_RANK_FD = 4        % 梁FDランク

    % 部材種別名称
    RANK_NONE = 0             % ランク対象外（RC等）
    MEMBER_RANK_NAME = {'FA', 'FB', 'FC', 'FD'}

    %% ブレース配置タイプ
    BRACE_MEMBER_TYPE_X = 1        % X型配置
    BRACE_MEMBER_TYPE_K_UPPER = 2  % K上形
    BRACE_MEMBER_TYPE_K_LOWER = 3  % K下形

    %% ブレースペア
    BRACE_MEMBER_PAIR_L = 1        % 左下がりブレース
    BRACE_MEMBER_PAIR_R = 2        % 右下がりブレース
    BRACE_MEMBER_PAIR_BOTH = 3     % 両方（入力専用、内部処理で展開される）
    BRACE_MEMBER_PAIR_BOTH_L = 4   % 両方の左下がりブレース
    BRACE_MEMBER_PAIR_BOTH_R = 5   % 両方の右下がりブレース

    %% ブレース通し
    BRACE_THROUGH_NONE = 0       % 通しなし
    BRACE_THROUGH_AUTO = 1       % 通し自動

    %% 剛部材倍率
    RIGID_SCALE = 1.d6        % 剛性倍率

    %% 最大フェーズ数
    MAX_NUM_PHASE = 100       % 最大フェーズ数
    
    %% UIモード
    UIMODE_CUI = 1;           % コマンドラインモード
    UIMODE_GUI = 2;           % GUIモード（設定ダイアログ）

    %% exitflag定義
    % 収束（正の値）
    EXITFLAG_CONVERGED = 1;           % 最適解に収束
    EXITFLAG_NO_IMPROVEMENT = 2;      % 改善が見られない（局所最適）
    EXITFLAG_TARGET_REACHED = 3;      % 目標値に到達

    % 停止条件（0）
    EXITFLAG_MAXITER = 0;             % 最大反復回数に到達

    % 最適化結果（負の値）
    EXITFLAG_NO_FEASIBLE = -1;         % 許容解なし
    EXITFLAG_TIMEOUT = -2;             % 時間制限到達
    EXITFLAG_USER_STOP = -3;           % ユーザー中断

    % ファイルエラー
    EXITFLAG_FILE_ERROR = -10;        % ファイルI/Oエラー

    % データエラー
    EXITFLAG_INPUT_ERROR = -100;       % 入力データエラー
    EXITFLAG_LIST_ERROR = -110;        % リストデータ内容エラー

    % 環境エラー
    EXITFLAG_ENV_ERROR = -200;         % 実行環境エラー

    % システムエラー
    EXITFLAG_LICENSE_ERROR = -500;     % ライセンス認証エラー
    EXITFLAG_INTERNAL_ERROR = -999;    % 予期しないエラー

    %% CSV 行末マーカー
    % ROW_END_MARKER: CSV 行末に出力する SS7 規約の論理行終端文字列
    % CONT_MARKER: body 最終列に置くと継続行扱いとなり ROW_END_MARKER を
    %   付与しない。marker 空は既定終端として ROW_END_MARKER を付与。
    ROW_END_MARKER = '<RE>';
    CONT_MARKER    = '<CONT>';
  end
  methods(Static)
    %% nvar_of_section_type
    function n = nvar_of_section_type(section_type)
    %nvar_of_section_type - 断面種別ごとの変数種別数を取得
    %
    %   n = PRM.nvar_of_section_type(section_type) は、断面種別が持つ
    %   変数の個数を返す。
    %
    %   入力引数:
    %     section_type - 断面種別 (PRM.WFS, PRM.HSS, PRM.BRB 等)
    %
    %   出力引数:
    %     n - 変数種別数（WFS: 4, HSS/HSR/BRB: 2, TB: 0）
    %
    %   例:
    %     n = PRM.nvar_of_section_type(PRM.WFS)  % returns 4
      switch section_type
        case {PRM.WFS, PRM.BWFS}
          n = 4;
        case {PRM.HSS, PRM.BHSS}
          n = 2;
        case {PRM.HSR, PRM.BHSR}
          n = 2;
        case PRM.BRB
          n = 2;
        case PRM.TB
          n = 0;
        otherwise
          error('未対応の断面種別です: %d', section_type)
      end
      return
    end
    
    %% load_case_name
    function lcname = load_case_name(idlc)
    %load_case_name - 荷重ケース短縮名を取得
    %
    %   lcname = PRM.load_case_name(idlc) は、組合せ前テーブル
    %   （設計応力表）用の短縮名を返す。
    %
    %   入力引数:
    %     idlc - 荷重ケースID (PRM.LT, PRM.EXP, PRM.EXN 等)
    %
    %   出力引数:
    %     lcname - 荷重ケース短縮名 ('G+P', 'EX+', 'EX-' 等)
    %
    %   例:
    %     PRM.load_case_name(PRM.EXP)  % 'EX+'
      switch idlc
        case PRM.LT,  lcname = 'G+P';
        case PRM.EXP, lcname = 'EX+';
        case PRM.EXN, lcname = 'EX-';
        case PRM.EYP, lcname = 'EY+';
        case PRM.EYN, lcname = 'EY-';
      end
      return
    end

    %% load_case_combo_name
    function lcname = load_case_combo_name(idlc)
    %load_case_combo_name - 荷重組合せケース名を取得
    %
    %   lcname = PRM.load_case_combo_name(idlc) は、断面算定表
    %   （S梁/S柱/ブレース）用の組合せ名を返す。
    %
    %   入力引数:
    %     idlc - 荷重ケースID (PRM.LT, PRM.EXP, PRM.EXN 等)
    %
    %   出力引数:
    %     lcname - 組合せ名 ('L', 'L+Ex', 'L-Ex' 等)
    %
    %   例:
    %     PRM.load_case_combo_name(PRM.EXP)  % 'L+Ex'
      switch idlc
        case PRM.LT,  lcname = 'L';
        case PRM.EXP, lcname = 'L+Ex';
        case PRM.EXN, lcname = 'L-Ex';
        case PRM.EYP, lcname = 'L+Ey';
        case PRM.EYN, lcname = 'L-Ey';
      end
      return
    end

    %% get_id_section_type
    function section_type = get_id_section_type(char_section_type)
    %get_id_section_type - 断面種別文字列から断面種別IDを取得
    %
    %   section_type = PRM.get_id_section_type(char_section_type) は、
    %   文字列形式の断面種別を数値IDに変換する。
    %
    %   入力引数:
    %     char_section_type - 断面種別文字列のセル配列
    %                         {'H', 'Ｈ', '□', 'アンボンドブレース(耐震)'}
    %
    %   出力引数:
    %     section_type - 断面種別ID配列
    %                    PRM.WFS, PRM.HSS, PRM.BRB, PRM.OTS 等
    %
    %   例:
    %     ids = PRM.get_id_section_type({'H', '□'})
    %     % returns [10; 20]
      n = length(char_section_type);
      section_type = nan(n,1);
      for i=1:n
        cst = char_section_type{i};
        if ismissing(cst)
          cst = '';
        end
        switch cst
          case 'H'
            section_type(i) = PRM.WFS;
          case 'Ｈ'
            section_type(i) = PRM.WFS;
          case '□'
            section_type(i) = PRM.HSS;
          case '○'
            section_type(i) = PRM.HSR;
          case '〇'
            section_type(i) = PRM.HSR;
          case 'アンボンドブレース(耐震)'
            section_type(i) = PRM.BRB;
          case '引張ブレース'
            section_type(i) = PRM.TB;
          case ''
            section_type(i) = PRM.OTS;
        end
      end
      return
    end
    
    %% get_id_ubb_type
    function ubb_type = get_id_ubb_type(char_ubb_type)
    %get_id_ubb_type - UBB種別文字列からUBB種別IDを取得
    %
    %   ubb_type = PRM.get_id_ubb_type(char_ubb_type) は、アンボンド
    %   ブレースの種別文字列を数値IDに変換する。
    %
    %   入力引数:
    %     char_ubb_type - UBB種別文字列のセル配列 ({'UB400','UB490'})
    %
    %   出力引数:
    %     ubb_type - UBB種別ID配列 (PRM.UB400, PRM.UB490, PRM.OTS)
    %
    %   例:
    %     ids = PRM.get_id_ubb_type({'UB400', 'UB490'})
    %     % returns [101400; 101490]
      n = length(char_ubb_type);
      ubb_type = nan(n,1);
      for i=1:n
        cut = char_ubb_type{i};
        if ismissing(cut)
          cut = '';
        end
        switch cut
          case 'UB400'
            ubb_type(i) = PRM.UB400;
          case 'UB490'
            ubb_type(i) = PRM.UB490;
          case ''
            ubb_type(i) = PRM.OTS;
        end
      end
      return
    end

    %% route_to_n_beam
    function n = route_to_n_beam(route)
    %route_to_n_beam - 設計ルートから梁設計用せん断力の割増率nを取得
    %
    %   n = PRM.route_to_n_beam(route) は、S梁の設計用せん断力
    %   Q_D = Q_L + n*Q_E に用いる割増率nをルート別に返す
    %   （SS7入力編 割増率n）。
    %
    %   入力引数:
    %     route - 設計ルート（PRM.ROUTE_1 等）
    %
    %   出力引数:
    %     n - 割増率（ROUTE_1/ROUTE_3=1.50, ROUTE_2_1=2.00,
    %                 ROUTE_2_2=1.50, その他=1.00）
      switch route
        case PRM.ROUTE_1,   n = 1.50;
        case PRM.ROUTE_2_1, n = 2.00;
        case PRM.ROUTE_2_2, n = 1.50;
        case PRM.ROUTE_3,   n = 1.50;
        otherwise,          n = 1.00;
      end
      return
    end

    %% get_tb_shape_code
    function shape_code = get_tb_shape_code(type_str)
    %get_tb_shape_code - TB種別文字列から形状コードを取得
    %
    %   shape_code = PRM.get_tb_shape_code(type_str) は、type 文字列の
    %   ハイフン前プレフィックスで形状を判定する。
    %
    %   入力引数:
    %     type_str - TB種別文字列（例: 'L-75x75x6'）
    %
    %   出力引数:
    %     shape_code - 形状コード（PRM.TB_L 等）
      tokens = split(type_str, '-');
      prefix = tokens{1};
      switch prefix
        case 'L'
          shape_code = PRM.TB_L;
        case '2L'
          shape_code = PRM.TB_2L;
        case '2L(並)'
          shape_code = PRM.TB_2LP;
        case '['
          shape_code = PRM.TB_C;
        case '2['
          shape_code = PRM.TB_2C;
        case 'TB'
          shape_code = PRM.TB_TB;
        case 'FB'
          shape_code = PRM.TB_FB;
        otherwise
          error('PRM:UnknownTbShape', '未知のTB形状: %s', type_str);
      end

      return
    end
  end
end
