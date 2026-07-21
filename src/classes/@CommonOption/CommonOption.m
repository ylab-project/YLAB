classdef CommonOption
%CommonOption - YLAB共通オプション保持クラス
%
%   YLABの実行に必要な各種オプション（入出力パス、計算機能フラグ、
%   最適化パラメータ等）をプロパティとして保持する。
%
%   備考:
%     - 既定値はプロパティブロックで直接指定する
%     - 実行前に validate() で必須値の検証を行う

  properties
    % --- ディレクトリパス ---
    approot (1,:) char
    prgroot (1,:) char
    inputfile (1,:) char
    outputfile (1,:) char
    solutionfile (1,:) char
    optionfile (1,:) char
    workdirpath (1,:) char
    historyfile (1,:) char
    matfile (1,:) char
    msgfile(1,:) char

    % --- 基本事項 ---
    num_basement_floor (1,1) double {mustBeNonnegative} = 0;
    num_penthouse_floor (1,1) double {mustBeNonnegative} = 0;
    gl_to_first_floor_height (1,1) double = 0;

    % --- フロー制御 ---
    version (1,:) char
    uimode (1,1) double = PRM.UIMODE_CUI
    exemode char {mustBeMember(exemode, {'OPT', 'GA', 'CHECK', ...
      'CONVERT'})} = 'OPT'
    developer_mode logical = false;
    do_limit_initial_girder_height(1,1) logical = false
    do_restration(1,1) logical = true
    do_restration_asr(1,1) logical = true
    % cgsr/jbs 集約復元（フェーズ1a: 単純 max/min 集約）
    do_aggregated_restore(1,1) logical = true
    do_cache(1,1) logical = false
    do_SA(1,1) logical = false
    discretization(1,1) logical = true
    do_writeout_pdf(1,1) logical = false;
    do_parallel(1,1) logical = true;
    save_full_result(1,1) logical = false;
    idtrial(1,1) double {mustBeNonnegative} = 0;
    idphase(1,1) double {mustBeNonnegative} = 999;

    % --- 途中結果読み込み ---
    idtrial_resume (1,1) double {mustBeNonnegative} = 1;
    idphase_resume (1,1) double {mustBeNonnegative} = 1;
    iter_resume(1,1) double {mustBeNonnegative} = 1;
    iter(1,1) double {mustBeNonnegative} = 0;

    % --- 断面リストの事前処理 ---
    do_preprocess_section_list(1,1) logical = true
    do_limit_wtratio_section(1,1) logical = true
    do_limit_slr_section(1,1) logical = true
    do_limit_jbs_section(1,1) logical = true

    % 保有耐力接合（仕口）の算定式・安全率α
    % PRM.JBS_STANDARD（基準解説書式）または PRM.JBS_AIJ（指針式）
    jbs_mu_formula (1,1) double = PRM.JBS_AIJ
    jbs_alpha_type (1,1) double = PRM.JBS_AIJ

    % 設計ルート（PRM.ROUTE_1/ROUTE_2_1/ROUTE_2_2/ROUTE_3）
    % 梁の設計用せん断力の割増率n の導出に使用（計算時参照）
    design_route (1,1) double = PRM.ROUTE_3

    % --- 計算機能 ---
    % 自重計算
    consider_self_weight (1,1) logical = true
    self_weight_extra_factor_girder (1,1) double {mustBeNonnegative} = 1;
    self_weight_extra_factor_column (1,1) double {mustBeNonnegative} = 1;

    % 鉄骨積算の重量増減率（SS7 Op.積算 3.1.1-5）
    steel_cost_weight_extra_factor_girder (1,1) double ...
      {mustBeNonnegative} = 1.215;
    steel_cost_weight_extra_factor_column (1,1) double ...
      {mustBeNonnegative} = 1.215;

    % 仕上げ荷重
    consider_finishing_material (1,1) logical = true
    finishing_material_s_column (1,1) double {mustBeNonnegative} = 500e-6
    finishing_material_s_girder (1,1) double {mustBeNonnegative} = 500e-6
    finishing_material_rc_column (1,1) double {mustBeNonnegative} = 500e-6
    finishing_material_rc_girder (1,1) double {mustBeNonnegative} = 500e-6

    % 構造階高の自動計算
    do_autoupdate_floor_height (1,1) logical = true

    % 構造スパン自動計算
    do_autoupdate_structural_span (1,1) logical = true
    
    % 剛域の自動計算
    consider_rigid_zone (1,1) logical = true

    % せん断変形
    consider_shear_deformation (1,1) logical = true

    % 梁水平面内変形の考慮（SS7 入力 2.3 応力計算条件 準拠）
    % PRM.GIRDER_HSTIFF_ZERO=剛性0（微小化、従来挙動）/ ACTUAL=原断面 /
    % RIGID=変形しない。鉛直/水平の別指定（YLABは剛性行列1本のため全
    % ケース共通）と部材別の個別指定（SS7 9.4 剛度増減率）は未対応
    girder_horizontal_stiffness_type (1,1) double = PRM.GIRDER_HSTIFF_ZERO

    % 横座屈の考慮
    consider_lateral_torsional_buckling (1,1) logical = true

    % 柱座屈長計算
    consider_column_buckling_length_factor (1,1) logical = true

    % 柱部材長のとり方（1:コンクリートとの重複を除く, 2:節点間）
    column_member_length_type (1,1) double = 1

    % 柱座屈長さ係数の自動計算入力値α
    brace_share_threshold (1,1) double = 0.7

    % スカラップ長
    consider_girder_scallop (1,1) logical = true
    girder_scallop_size (1,1) double {mustBeNonnegative} = 35

    % 基礎の引き抜きの考慮
    consider_foundation_uplift (1,1) logical = false

    % 梁・柱面での断面算定
    consider_allowable_stress_at_face (1,1) logical = true

    % SN材H形鋼の幅厚比制限値の考慮
    consider_SNH_WTRATIO (1,1) logical = true

    % 床による梁剛性の考慮
    consider_composite_slab_effect_s (1,1) double = ...
      PRM.COMPOSITE_SLAB_WIDTH
    composite_slab_coefficient_s (1,2) double ...
      {mustBeNonnegative} = [1.3 1.5];
    consider_composite_slab_effect_rc (1,1) double = ...
      PRM.COMPOSITE_SLAB_WIDTH
    composite_slab_coefficient_rc (1,2) double ...
      {mustBeNonnegative} = [1.3 1.5];

    % RC柱・梁Aの計算方法（YLABではAの腰壁・垂壁は未対応）
    rc_shear_area_type (1,1) double = PRM.RC_AREA_WALL_ONLY
    rc_axial_area_type (1,1) double = PRM.RC_AREA_FLOOR_WALL

    % ブレースの取り付き位置
    position_brace_foundation_girder (1,1) double = ...
      PRM.BRACE_FOUNDATION_GIRDER_TOP

    % 曲げの設計におけるウェブの考慮（梁中央部）
    consider_web_at_girder_center (1,1) logical = false

    % 曲げの設計におけるウェブの考慮（梁端部）
    consider_web_at_girder_end (1,1) logical = false

    % S梁の軸力を考慮した検定（SS7マニュアル 2.5.4 準拠）
    % 1=しない, 2=する(すべて), 3=する(軸力が生じた梁のみ)(初期値)
    s_girder_axial_design (1,1) double = PRM.S_GIRDER_AXIAL_AUTO

    % 最適化計算オプション
    penalty_method = PRM.PENALTY_MAXIMUM;
    local_search_method (1,:) char {mustBeMember(local_search_method, ...
      {'LSR', 'LSFR'})} = 'LSFR'
    do_lsfr_all_phases (1,1) logical = false
    max_fusion_depth (1,1) double {mustBeInteger, ...
      mustBeGreaterThanOrEqual(max_fusion_depth, 2)} = 6
    max_num_fusion_seed (1,1) double {mustBePositive, mustBeInteger} = 50
    max_num_fusion_candidate (1,1) double {mustBePositive, ...
      mustBeInteger} = 20
    max_num_restoration_seed (1,1) double {mustBePositive, ...
      mustBeInteger} = 10
    max_num_restoration_candidate (1,1) double {mustBePositive, ...
      mustBeInteger} = 10
    lsfr_diagnostic_file (1,:) char = ''

    % 制約条件オプション
    coptions

    % 繰返し数
    iter_set (1,:) double {mustBePositive} = 1
    maxiter_in_LS (1,1) double {mustBeNonnegative} = inf
    maxphase (1,1) double {mustBeNonnegative} = inf
    maxcache (1,1) double {mustBeNonnegative} = 200

    % 画面出力
    display(1,:) char {mustBeMember(display, {'None', 'Iter10', ...
      'Iter', 'Final'})} = 'Iter'
   
    % --- 制約条件計算用パラメータ ---
    type % 保留
    reqHgap(1,1) double {mustBeNonnegative} = 150
    dmax(1,1) double
    tolHgap(1,1) double {mustBeNonnegative} = 20;
    tolBgap(1,1) double {mustBeNonnegative} = 10;
    tolDgap(1,1) double {mustBeNonnegative} = 10;
    tolMaxDgap(1,1) double {mustBeNonnegative} = 50;
    tolRestoreCgr(1,1) double {mustBeNonnegative} = 0.0;
    tolRestoreSr(1,1) double {mustBeNonnegative} = 0.0;
    tolActive(1,1) double = -0.05;

    % --- 最適化計算用パラメータ ---
    r(1,1) double {mustBePositive} = 2;
    mu0 double = [0.2*ones(1,PRM.MAX_NUM_PHASE-1) 1];
    mu(1,1) double;
    tau(1,1) double = 0;
    omega(1,1) double = 0;

    % 計算用サイズ
    numc(1,1) double
    numvio(1,1) double

    % 初期解
    x0(1,:) double

    % --- 出力制御用パラメータ ---
    output_girder_list_label = [];
    output_column_list_label = [];

    % 断面算定表で全部材を出力するか（false=代表1部材）
    section_calc_all_members (1,1) logical = true

    % SS7互換の旧フォーマット出力（S梁検定比一覧）
    do_legacy_output (1,1) logical = false
  end

  properties (Dependent)
    % lsfr_diagnostic_file が指定されているか（診断収集ゲート）
    has_lsfr_diagnostic
  end

  methods
    function obj = CommonOption()
    %CommonOption - コンストラクタ
    %
    %   obj = CommonOption() は、CommonOptionインスタンスを生成し、
    %   制約条件オプション(coptions)に ConstraintOption を割り当てる。
    %
    %   出力引数:
    %     obj - CommonOptionインスタンス
      obj.coptions = ConstraintOption();
    end

    function value = get.has_lsfr_diagnostic(obj)
    %get.has_lsfr_diagnostic - 診断収集ゲートの取得
    %
    %   value = get.has_lsfr_diagnostic(obj) は、lsfr_diagnostic_file が
    %   指定されているか（非空か）を論理値で返す。
    %
    %   出力引数:
    %     value - 診断ファイル指定時に true (1,1 logical)
      value = ~isempty(obj.lsfr_diagnostic_file);
    end

    function validate(obj)
    %validate - オプション値の検証
    %
    %   validate(obj) は、必須プロパティの型・範囲と必須パス
    %   (approot, prgroot, inputfile, outputfile) の設定有無を
    %   検証し、不正時はエラーを投げる。
    %
    %   入力引数:
    %     obj - CommonOptionインスタンス
      va_ = @validateattributes;
      nn_ = {'scalar', 'nonnegative'};
      po_ = {'scalar', 'positive'};
      dbl_ = {'double'};
      va_(obj.num_basement_floor, dbl_, nn_);
      va_(obj.num_penthouse_floor, dbl_, nn_);
      va_(obj.gl_to_first_floor_height, dbl_, {'scalar'});
      va_(obj.self_weight_extra_factor_girder, dbl_, po_);
      va_(obj.self_weight_extra_factor_column, dbl_, po_);
      va_(obj.girder_scallop_size, dbl_, nn_);
      va_(obj.maxiter_in_LS, dbl_, po_);
      va_(obj.maxcache, dbl_, po_);
      va_(obj.r, dbl_, po_);
      
      % 必須パスの検証
      if isempty(obj.approot)
        error('CommonOption:InvalidPath', 'approot must be set');
      end
      if isempty(obj.prgroot)
        error('CommonOption:InvalidPath', 'prgroot must be set');
      end
      if isempty(obj.inputfile)
        error('CommonOption:InvalidPath', 'inputfile must be set');
      end
      if isempty(obj.outputfile)
        error('CommonOption:InvalidPath', 'outputfile must be set');
      end
    end

    function setDefaultValues(~)
    %setDefaultValues - 既定値設定（no-op、過去互換用）
    %
    %   setDefaultValues(obj) は呼び出し互換性のため残されているが、
    %   既定値はプロパティブロックに移管済みのため何も行わない。
    %
    %   入力引数:
    %     obj - CommonOptionインスタンス（未使用）
    %
    %   備考:
    %     - 全呼び出し元の削除完了後に本メソッドも削除予定
    end
  end
end