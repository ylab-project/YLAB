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
    %% 座標・方向
    X = 1;                % X方向
    Y = 2;                % Y方向  
    Z = 3;                % Z方向
    XY = 12;              % XY方向(45度方向)

    %% 節点種別
    SUPPORT = 100         % 支点節点

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

    % 断面種別
    WFS  = 10   % Ｈ形鋼
    HSS  = 20   % 角形鋼管
    HSR  = 30   % 円形鋼管
    RCRS = 50   % ＲＣ矩形断面
    BRB  = 101  % 座屈拘束ブレース
    HBR  = 110  % 水平ブレース
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
    VTYPE_SET_BOUNDS = [...
      PRM.WFS_H PRM.WFS_B PRM.WFS_TW PRM.WFS_TF ...
      PRM.HSS_D PRM.HSS_T PRM.HSR_D PRM.HSR_T ...
      PRM.BRB_V1 PRM.BRB_V2];

    %% UB種別
    UB400 = 101400
    UB490 = 101490
    
    %% ブレース種別
    BRACE_TENSION = 1001              % 引張のみ
    BRACE_TENSION_COMPRESSION = 1002  % 引張圧縮

    %% 物理定数
    GRAVITY = 9.8         % 重力加速度 [m/s2]
    RHOS = 7.85           % 鋼材密度 [t/m3]
    RHORC = 2.45          % RC密度 [t/m3]
    % RIGID_COEF = 1.d5
    RIGID_COEF = 1.d4
    % RIGID_COEF = 1.d3
    % RIGID_COEF = 1.d1
    MAX_SECTION_LIST = 4;

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

    %% ブレース取付位置
    BRACE_FOUNDATION_GIRDER_TOP = 1     % 梁上端
    BRACE_FOUNDATION_GIRDER_CENTER = 2  % 梁中心

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

    %% 節点種類
    NODE_STANDARD = 0         % 標準節点
    NODE_FLEX_DIAPHRAGM = 10  % 柔床節点
    NODE_BRACE_FOR_GIRDER = 98  % ブレース用梁分割節点
    NODE_BRACE_FOR_COLUMN = 99  % ブレース用柱分割節点
    
    %% 梁種類
    GIRDER_STANDARD = 0       % 標準梁
    GIRDER_FOR_KBRACE1 = 96   % K形ブレース梁1（左側）
    GIRDER_FOR_KBRACE2 = 97   % K形ブレース梁2（右側）

    %% 柱種類
    COLUMN_STANDARD = 0       % 標準柱
    COLUMN_FOR_BRACE1 = 98    % ブレース柱1
    COLUMN_FOR_BRACE2 = 99    % ブレース柱2

    %% 部材群種別
    COLUMN_RANK_FA = 1        % 柱FAランク
    COLUMN_RANK_FB = 2        % 柱FBランク
    COLUMN_RANK_FC = 3        % 柱FCランク
    COLUMN_RANK_FD = 4        % 柱FDランク
    GIRDER_RANK_FA = 1        % 梁FAランク
    GIRDER_RANK_FB = 2        % 梁FBランク
    GIRDER_RANK_FC = 3        % 梁FCランク
    GIRDER_RANK_FD = 4        % 梁FDランク

    %% ブレース配置タイプ
    BRACE_MEMBER_TYPE_X = 1        % X型配置
    BRACE_MEMBER_TYPE_K_UPPER = 2  % K上形
    BRACE_MEMBER_TYPE_K_LOWER = 3  % K下形

    %% ブレースペア
    BRACE_MEMBER_PAIR_L = 1        % 左（下がり）ブレース
    BRACE_MEMBER_PAIR_R = 2        % 右（下がり）ブレース
    BRACE_MEMBER_PAIR_BOTH = 3     % 両方（入力専用、内部処理で展開される）
    BRACE_MEMBER_PAIR_BOTH_L = 4   % 両方の左（下がり）ブレース
    BRACE_MEMBER_PAIR_BOTH_R = 5   % 両方の右（下がり）ブレース

    %% 剛部材倍率
    RIGID_SCALE = 1.d6        % 剛性倍率

    %% 最大フェーズ数
    MAX_NUM_PHASE = 10        % 最大フェーズ数
    
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

    % 実行時エラー（負の値）
    EXITFLAG_NO_FEASIBLE = -1;        % 実行可能解なし
    EXITFLAG_TIMEOUT = -2;            % 時間制限に到達
    EXITFLAG_USER_STOP = -3;          % ユーザーによる中断
    EXITFLAG_INPUT_ERROR = -10;       % 入力データエラー
    EXITFLAG_CONSTRAINT_ERROR = -11;  % 制約条件エラー（強度/変形など）
    EXITFLAG_SECTION_ERROR = -12;     % 断面リスト関連エラー

    % システム/環境エラー
    EXITFLAG_LICENSE_ERROR = -50;     % ライセンス認証エラー
    
    % 内部エラー
    EXITFLAG_INTERNAL_ERROR = -99;    % 予期しないエラー
  end
  methods(Static)
    %% nvar_of_section_type
    function n = nvar_of_section_type(section_type)
      % 断面種別ごとの変数種別数を取得
      %
      % 各断面種別が持つ変数の個数を返す。
      %
      % Inputs:
      %   section_type - 断面種別 (PRM.WFS, PRM.HSS, PRM.BRB)
      %
      % Outputs:
      %   n - 変数種別数
      %       WFS: 4 (H, B, tw, tf)
      %       HSS: 2 (D, t)
      %       BRB: 2 (V1, V2)
      %
      % Example:
      %   n = PRM.nvar_of_section_type(PRM.WFS)  % returns 4
      switch section_type
        case PRM.WFS
          n = 4;
        case PRM.HSS
          n = 2;
        case PRM.HSR
          n = 2;
        case PRM.BRB
          n = 2;
        otherwise
          error('WFS,HSS,HSR,BRBのいずれかを指定してください')
      end
      return
    end
    
    %% load_case_name
    function lcname = load_case_name(idlc)
      % 荷重ケースIDから荷重ケース名を取得
      %
      % Inputs:
      %   idlc - 荷重ケースID (PRM.LT, PRM.EXP, etc.)
      %
      % Outputs:
      %   lcname - 荷重ケース名文字列
      %
      % Example:
      %   name = PRM.load_case_name(PRM.LT)  % returns 'G+P'
      switch idlc
        case PRM.LT
          lcname = 'G+P';
        case PRM.EXP
          lcname = 'L+Ex';
        case PRM.EXN
          lcname = 'L-Ex';
        case PRM.EYP
          lcname = 'L+Ey';
        case PRM.EYN
          lcname = 'L-Ey';
      end
      return
    end
    
    %% get_id_section_type
    function section_type = get_id_section_type(char_section_type)
      % 断面種別文字列から断面種別IDを取得
      %
      % 文字列形式の断面種別を数値IDに変換する。
      %
      % Inputs:
      %   char_section_type - 断面種別文字列のセル配列
      %                       {'H', 'Ｈ', '□', 'アンボンドブレース(耐震)'}
      %
      % Outputs:
      %   section_type - 断面種別ID配列
      %                  PRM.WFS, PRM.HSS, PRM.BRB, PRM.OTS
      %
      % Example:
      %   ids = PRM.get_id_section_type({'H', '□'})
      %   % returns [10; 20]
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
          case ''
            section_type(i) = PRM.OTS;
        end
      end
      return
    end
    
    %% get_id_ubb_type
    function ubb_type = get_id_ubb_type(char_ubb_type)
      % UBB種別文字列からUBB種別IDを取得
      %
      % アンボンドブレースの種別文字列を数値IDに変換する。
      %
      % Inputs:
      %   char_ubb_type - UBB種別文字列のセル配列
      %                   {'UB400', 'UB490'}
      %
      % Outputs:
      %   ubb_type - UBB種別ID配列
      %              PRM.UB400, PRM.UB490, PRM.OTS
      %
      % Example:
      %   ids = PRM.get_id_ubb_type({'UB400', 'UB490'})
      %   % returns [101400; 101490]
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
  end
end
