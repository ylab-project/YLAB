classdef SectionPropertyCalculator < handle
  %SectionPropertyCalculator 断面性能計算クラス
  %   SectionPropertyCalculatorは、断面および部材のコスト係数、
  %   応力係数、材料特性の計算を担当します。SectionManagerから
  %   性能計算関連の責務を分離した専門クラスです。
  %
  %   SectionPropertyCalculator プロパティ:
  %     nlist - 断面リスト数
  %     idme2sec - 部材-断面マッピング
  %
  %   SectionPropertyCalculator メソッド:
  %     getSectionCostFactor - 断面コスト係数を取得
  %     getMemberCostFactor - 部材コスト係数を取得
  %     getSectionStressFactor - 断面応力係数を取得
  %     extractSectionMaterialF - 断面の材料F値を抽出
  %     extractMemberMaterialF - 部材の材料F値を抽出
  %     mapSectionToMaterial - 断面-材料IDマッピングを取得
  %     mapMemberToMaterial - 部材-材料IDマッピングを取得
  %
  %   例:
  %     calc = SectionPropertyCalculator(secList, idMapper);
  %     cost = calc.getSectionCostFactor(idsec);
  %
  %   参考:
  %     SectionManager, IdMapper

  properties(Access=private)
    % 必要なデータへの直接参照
    secList_   % SectionListHandlerへの参照
    idMapper_  % IdMapperへの参照
    material_  % 材料データの実体を保持
    idsec2mat_ % デフォルト断面→材料IDマッピング
    sectionCostFactor_ % 断面コスト係数初期値
    sectionStressFactor_ % 断面応力係数初期値
  end

  properties(Dependent)
    material   % 材料データへの公開読み取り専用アクセス（Dependent）
    nlist      % 断面リスト数
    idme2sec   % 部材-断面マッピング
  end

  methods
    function obj = SectionPropertyCalculator(secList, material, ...
        idsec2mat, idMapper)
      %SectionPropertyCalculator コンストラクタ
      %   calc = SectionPropertyCalculator(secList, material, ...
      %     idsec2mat, idMapper) は、
      %   断面性能計算オブジェクトを作成します。
      %
      %   入力引数:
      %     secList - SectionListHandlerオブジェクト
      %     material - 材料データオブジェクト
      %     idsec2mat - デフォルト断面→材料IDマッピング（必須）
      %     idMapper - IdMapperオブジェクト
      %
      %   例:
      %     calc = SectionPropertyCalculator(secList, material, ...
      %       idsec2mat, idMapper);

      % 引数チェック
      if nargin < 4
        error('SectionPropertyCalculator:InsufficientArguments', ...
          'SectionPropertyCalculatorは4つの引数が必要です');
      end
      
      % 必要なデータへの参照を保持
      obj.secList_ = secList;                  % SectionListHandler参照
      obj.material_ = material;                % 材料データの実体を保持
      obj.idsec2mat_ = idsec2mat;              % デフォルト材料IDマッピング
      obj.idMapper_ = idMapper;                % IdMapper参照
      
      % sectionCostFactor/sectionStressFactorの初期化
      nsec = length(idsec2mat);
      obj.sectionCostFactor_ = zeros(nsec, 1);    % ゼロで初期化
      obj.sectionStressFactor_ = ones(nsec, 1);   % 1で初期化
    end


    function nlist_ = get.nlist(obj)
      % 断面リスト数を取得
      if ~isempty(obj.secList_)
        nlist_ = obj.secList_.nlist;
      else
        nlist_ = 0;
      end
    end
    
    function idme2sec_ = get.idme2sec(obj)
      % 部材-断面マッピングをIdMapperから取得
      if ~isempty(obj.idMapper_)
        idme2sec_ = obj.idMapper_.idme2sec;
      else
        idme2sec_ = [];
      end
    end
    
    function mat = get.material(obj)
      % 材料データへの公開読み取り専用アクセス
      mat = obj.material_;
    end
    
    %% mapSectionToMaterial
    function idmat = mapSectionToMaterial(obj)
      %mapSectionToMaterial 断面から材料IDへのマッピング
      %   idmat = mapSectionToMaterial(obj) は、
      %   各断面に対応する材料IDへのマッピングを生成します。
      %
      %   出力引数:
      %     idmat - 断面から材料へのIDマッピング [nsec × 1]
      %
      %   例:
      %     idmat = calc.mapSectionToMaterial();
      %
      %   参考:
      %     mapMemberToMaterial, extractSectionMaterialF
      
      % IdMapperのメソッドに委譲
      idmat = obj.idMapper_.mapSectionToMaterial(obj.secList_);
      return
    end
    
    %% mapMemberToMaterial
    function idmat = mapMemberToMaterial(obj)
      %mapMemberToMaterial 部材から材料IDへのマッピング
      %   idmat = mapMemberToMaterial(obj) は、
      %   各部材に対応する材料IDへのマッピングを生成します。
      %
      %   出力引数:
      %     idmat - 部材から材料へのIDマッピング [nmember × 1]
      %
      %   例:
      %     idmat = calc.mapMemberToMaterial();
      %
      %   参考:
      %     mapSectionToMaterial, extractMemberMaterialF
      
      % IdMapperのメソッドに委譲
      idmat = obj.idMapper_.mapMemberToMaterial(obj.secList_);
      return
    end
  end
end