classdef CommonOption
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

    % --- フロー制御 ---
    version (1,:) char
    uimode (1,1) double = PRM.UIMODE_CUI
    exemode char {mustBeMember(exemode,{'OPT', 'GA', 'CHECK', 'CONVERT'})} = 'OPT'
    developer_mode logical = false;
    % do_limit_initial_girder_height(1,1) logical = true
    do_limit_initial_girder_height(1,1) logical = false
    do_restration(1,1) logical = true
    do_restration_asr(1,1) logical = true
    % do_restration(1,1) logical = false
    % do_cache(1,1) logical = true
    do_cache(1,1) logical = false
    % do_SA(1,1) logical = true
    do_SA(1,1) logical = false
    discretization(1,1) logical = true
    do_writeout_pdf(1,1) logical = false;
    do_parallel(1,1) logical = true;
    % do_parallel(1,1) logical = false;
    save_full_result(1,1) logical = false;
    idtrial(1,1) double {mustBeNonnegative} = 0;
    idphase(1,1) double {mustBeNonnegative} = 999;

    % --- 途中結果読み込み ---
    idtrial_resume (1,1) double {mustBeNonnegative} = 1;
    idphase_resume (1,1) double {mustBeNonnegative} = 1;
    iter_resume(1,1) double {mustBeNonnegative} = 0;
    iter(1,1) double {mustBeNonnegative} = 0;

    % --- 断面リストの事前処理 ---
    do_limit_wtratio_section(1,1) logical = true
    do_limit_slr_section(1,1) logical = true
    do_limit_jbs_section(1,1) logical = true

    % --- 計算機能 ---
    % 自重計算
    consider_self_weight (1,1) logical = true
    self_weight_extra_factor_girder (1,1) double {mustBeNonnegative} = 1;
    self_weight_extra_factor_column (1,1) double {mustBeNonnegative} = 1;

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

    % 横座屈の考慮
    consider_lateral_torsional_buckling (1,1) logical = true

    % 柱座屈長計算
    consider_column_buckling_length_factor (1,1) logical = true

    % スカラップ長
    consider_girder_scallop (1,1) logical = true
    girder_scallop_size (1,1) double {mustBeNonnegative} = 35

    % 基礎の引き抜きの考慮
    % consider_foundation_uplift logical (1,1) = true
    consider_foundation_uplift (1,1) logical = false

    % 梁・柱面での断面算定
    consider_allowable_stress_at_face (1,1) logical = true

    % SN材H形鋼の幅厚比制限値の考慮
    consider_SNH_WTRATIO (1,1) logical = true

    % 床による梁剛性の考慮
    consider_composite_slab_effect_s (1,1) double = PRM.COMPOSITE_SLAB_WIDTH
    composite_slab_coefficient_s (1,2) double {mustBeNonnegative} = [1.3 1.5];
    consider_composite_slab_effect_rc (1,1) double = PRM.COMPOSITE_SLAB_WIDTH
    composite_slab_coefficient_rc (1,2) double {mustBeNonnegative} = [1.3 1.5];

    % ブレースの取り付き位置
    position_brace_foundation_girder (1,1) double = ...
      PRM.BRACE_FOUNDATION_GIRDER_TOP

    % 曲げの設計におけるウェブの考慮（梁中央部）
    consider_web_at_girder_center (1,1) logical = false

    % 曲げの設計におけるウェブの考慮（梁端部）
    consider_web_at_girder_end (1,1) logical = false

    % 最適化計算オプション
    % penalty_method = PRM.PENALTY_SUM_TOTAL;
    penalty_method = PRM.PENALTY_MAXIMUM;

    % 制約条件オプション
    coptions

    % 繰返し数
    iter_set (1,:) double {mustBePositive} = 1
    maxiter_in_LS (1,1) double {mustBeNonnegative} = inf
    maxphase (1,1) double {mustBeNonnegative} = inf
    % maxcache (1,1) double = 1000
    maxcache (1,1) double {mustBeNonnegative} = 200

    % 画面出力
    % display(1,:) char {mustBeMember(...
    %   display,{'None','Iter10','Iter','Final'})} = 'Iter10'
    display(1,:) char {mustBeMember(...
      display,{'None','Iter10','Iter','Final'})} = 'Iter'
   
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
    % 通常
    % mu0 double = 0.3*ones(1,PRM.MAX_NUM_PHASE);
    mu0 double = [0.2 ones(1,PRM.MAX_NUM_PHASE-1)];
    mu(1,1) double;
    tau(1,1) double = 0;
    omega(1,1) double = 0;

    % 計算用サイズ
    numc(1,1) double
    numvio(1,1) double

    % 初期解
    x0(1,:) double

    % --- コスト変化量操作 ---
    do_progressive_cost_change = false;
    progressive_cost_change_iter = 5;

    % --- 出力制御用パラメータ ---
    output_girder_list_label = [];
    output_column_list_label = [];
  end

  methods
    function obj = CommonOption()
      % コンストラクタ
      obj.coptions = ConstraintOption();
    end

    function validate(obj)
      % オプション値の検証
      validateattributes(obj.num_basement_floor, {'double'}, {'scalar', 'nonnegative'});
      validateattributes(obj.num_penthouse_floor, {'double'}, {'scalar', 'nonnegative'});
      validateattributes(obj.self_weight_extra_factor_girder, {'double'}, {'scalar', 'positive'});
      validateattributes(obj.self_weight_extra_factor_column, {'double'}, {'scalar', 'positive'});
      validateattributes(obj.girder_scallop_size, {'double'}, {'scalar', 'nonnegative'});
      validateattributes(obj.maxiter_in_LS, {'double'}, {'scalar', 'positive'});
      validateattributes(obj.maxcache, {'double'}, {'scalar', 'positive'});
      validateattributes(obj.r, {'double'}, {'scalar', 'positive'});
      
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

    function setDefaultValues(obj)
      % デフォルト値の設定
      % 注: プロパティブロックで既に定義済みの値は
      % 二重管理を避けるためコメントアウト（経過措置）
      % obj.uimode = 'MATLAB';
      % obj.exemode = 'OPT';
      % obj.do_limit_initial_girder_height = false;
      % obj.do_restration = true;
      % obj.do_restration_asr = true;
      % obj.do_cache = false;
      % obj.do_SA = false;
      % obj.discretization = true;
      % obj.do_writeout_pdf = false;
      % obj.do_parallel = true;
      % obj.save_full_result = false;
      % obj.idtrial = 0;
      % obj.idphase = 999;
      % obj.idtrial_resume = 1;
      % obj.idphase_resume = 1;
      % obj.iter_resume = 0;
      % obj.iter = 0;
      % obj.do_limit_wtratio_section = true;
      % obj.do_limit_slr_section = true;
      % obj.do_limit_jbs_section = true;
      % obj.consider_self_weight = true;
      % obj.self_weight_extra_factor_girder = 1;
      % obj.self_weight_extra_factor_column = 1;
      % obj.consider_finishing_material = true;
      % obj.finishing_material_s_column = 500e-6;
      % obj.finishing_material_s_girder = 500e-6;
      % obj.finishing_material_rc_girder = 500e-6;
      % obj.finishing_material_rc_column = 500e-6;
      % obj.do_autoupdate_floor_height = true;
      % obj.do_autoupdate_structural_span = true;
      % obj.consider_rigid_zone = true;
      % obj.consider_shear_deformation = true;
      % obj.consider_lateral_torsional_buckling = true;
      % obj.consider_column_buckling_length_factor = true;
      % obj.consider_girder_scallop = true;
      % obj.girder_scallop_size = 35;
      % obj.consider_foundation_uplift = false;
      % obj.consider_allowable_stress_at_face = true;
      % obj.consider_SNH_WTRATIO = true;
      % obj.consider_composite_slab_effect_s = PRM.COMPOSITE_SLAB_WIDTH;
      % obj.composite_slab_coefficient_s = [1.3 1.5];
      % obj.consider_composite_slab_effect_rc = PRM.COMPOSITE_SLAB_WIDTH;
      % obj.composite_slab_coefficient_rc = [1.3 1.5];
      % obj.position_brace_foundation_girder = PRM.BRACE_FOUNDATION_GIRDER_TOP;
      % obj.consider_web_at_girder_center = false;
      % obj.consider_web_at_girder_end = false;
      % obj.penalty_method = PRM.PENALTY_MAXIMUM;
      % obj.iter_set = 1;
      % obj.maxiter_in_LS = inf;
      % obj.maxcache = 200;
      % obj.display = 'Iter';
      % obj.reqHgap = 150;
      % obj.tolHgap = 20;
      % obj.tolBgap = 10;
      % obj.tolDgap = 10;
      % obj.tolMaxDgap = 50;
      % obj.tolRestoreCgr = 0.0;
      % obj.tolRestoreSr = 0.0;
      % obj.tolActive = -0.05;
      % obj.r = 2;
      % obj.mu0 = [0.2 ones(1,PRM.MAX_NUM_PHASE-1)];
      % obj.tau = 0;
      % obj.omega = 0;
      % obj.do_progressive_cost_change = false;
      % obj.progressive_cost_change_iter = 5;
    end
  end
end