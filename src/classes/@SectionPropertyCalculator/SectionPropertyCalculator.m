classdef SectionPropertyCalculator < handle
  %SectionPropertyCalculator 断面性能計算クラス
  %   SectionPropertyCalculatorは、断面および部材のコスト係数、
  %   応力係数、材料特性の計算を担当します。SectionManagerから
  %   性能計算関連の責務を分離した専門クラスです。
  %
  %   SectionPropertyCalculator プロパティ:
  %     nlist - 断面リスト数
  %
  %   SectionPropertyCalculator メソッド:
  %     getSectionCostFactor - 断面コスト係数を取得
  %     getSectionCostConstant - 断面コスト定数を取得
  %     getMemberCostFactor - 部材コスト係数を取得
  %     getSectionStressFactor - 断面応力係数を取得
  %     extractSectionMaterialF - 断面の材料F値と材料番号を抽出
  %     extractMemberMaterialF - 部材の材料F値を抽出
  %     mapSectionToMaterial - 断面-材料IDマッピングを取得
  %     mapMemberToMaterial - 部材-材料IDマッピングを取得
  %
  %   例:
  %     calc = SectionPropertyCalculator(secList, material, idsec2mat);
  %     cost = calc.getSectionCostFactor(idsec);
  %
  %   参考:
  %     SectionManager, IdMapper

  properties(Access=private)
    % 必要なデータへの直接参照
    secList_   % SectionListHandlerへの参照
    material_  % 材料データの実体を保持
    idsec2mat_ % デフォルト断面→材料IDマッピング
    sectionCostFactor_ % 断面コスト係数初期値
    sectionCostConstant_ % 断面コスト定数初期値
    sectionStressFactor_ % 断面応力係数初期値
  end

  properties(Dependent)
    material   % 材料データへの公開読み取り専用アクセス（Dependent）
    nlist      % 断面リスト数
  end

  methods
    function obj = SectionPropertyCalculator(secList, material, idsec2mat)
      %SectionPropertyCalculator - 断面と材料の対応を保持する
      %
      %   obj = SectionPropertyCalculator(secList, material, ...
      %   idsec2mat)
      %   は、断面リストと材料データを保存し、材料番号の参照を初期化する。
      %
      %   入力引数:
      %     secList - 材料・係数を含む断面リスト
      %     material - 材料定数を持つ構造体
      %     idsec2mat - 各断面の既定材料番号 [nsec×1]
      %
      %   出力引数:
      %     obj - 断面性能計算オブジェクト

      if nargin < 3
        error('SectionPropertyCalculator:InsufficientArguments', ...
          'SectionPropertyCalculatorは3つの引数が必要です');
      end

      % 必要なデータへの参照を保持
      obj.secList_ = secList;                  % SectionListHandler参照
      obj.material_ = material;                % 材料データの実体を保持
      obj.idsec2mat_ = idsec2mat;              % デフォルト材料IDマッピング

      % sectionCostFactor/CostConstant/StressFactorの初期化
      nsec = length(idsec2mat);
      obj.sectionCostFactor_ = zeros(nsec, 1);
      obj.sectionCostConstant_ = zeros(nsec, 1);
      obj.sectionStressFactor_ = ones(nsec, 1);
    end

    function nlist_ = get.nlist(obj)
      %get.nlist - 断面リスト数を取得する
      %
      %   nlist_ = obj.nlist
      %
      %   入力引数:
      %     obj - SectionPropertyCalculator オブジェクト
      %
      %   出力引数:
      %     nlist_ - 断面リスト数
      if ~isempty(obj.secList_)
        nlist_ = obj.secList_.nlist;
      else
        nlist_ = 0;
      end
    end

    function mat = get.material(obj)
      %get.material - 材料データ構造体を取得する
      %
      %   mat = obj.material
      %
      %   入力引数:
      %     obj - SectionPropertyCalculator オブジェクト
      %
      %   出力引数:
      %     mat - 材料データ構造体
      mat = obj.material_;
    end

    %% mapSectionToMaterial
    function idmat = mapSectionToMaterial(obj, idsec2slist)
      %mapSectionToMaterial - 現在の断面リスト対応から材料番号を返す
      %
      %   idmat = mapSectionToMaterial(obj, idsec2slist)
      %   は、idsec2slistで採用した各断面の材料番号を取得する。
      %
      %   入力引数:
      %     obj - 断面性能計算オブジェクト
      %     idsec2slist - 断面リストと候補断面の番号 [nsec×2]
      %
      %   出力引数:
      %     idmat - 断面順の材料番号 [nsec×1]

      idmat = obj.extractSectionMaterialId(idsec2slist);
      return
    end

    %% mapMemberToMaterial
    function idmat = mapMemberToMaterial(obj, idsec2slist, member)
      %mapMemberToMaterial - 現在の部材順に材料番号を返す
      %
      %   idmat = mapMemberToMaterial(obj, idsec2slist, member)
      %   は、採用断面の材料番号をmemberの断面番号で参照する。
      %
      %   入力引数:
      %     obj - 断面性能計算オブジェクト
      %     idsec2slist - 断面リストと候補断面の番号 [nsec×2]
      %     member - 現在の解析部材。property.idsecを参照する。
      %
      %   出力引数:
      %     idmat - 部材順の材料番号 [nme×1]

      idmat = obj.extractMemberMaterialId(idsec2slist, member);
      return
    end
  end
end
