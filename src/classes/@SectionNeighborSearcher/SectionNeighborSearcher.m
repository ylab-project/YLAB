classdef SectionNeighborSearcher < handle
%SectionNeighborSearcher 近傍断面探索クラス
%   断面の近傍探索と最近傍検索を行うクラス。
%   最適化アルゴリズムに対して次の候補断面を提供します。
%
%   プロパティ:
%     idHgap2var - 梁せい差評価の変数IDペア [ngap×2]
%     idHgap2sec - 梁せい差評価の断面IDペア [ngap×2]
%     options    - オプション構造体（reqHgap, tolHgapを含む）
%
%   参考:
%     SectionManager

properties (SetAccess = private)
  idHgap2var_  % 梁せい差評価の変数IDペア（内部） [ngap×2]
  idHgap2sec_  % 梁せい差評価の断面IDペア（内部） [ngap×2]
  options      % オプション構造体（reqHgap, tolHgapを含む）
  idMapper_    % IDマッピングオブジェクト
  standardAccessor_ % 標準値アクセサオブジェクト
  constraintValidator_ % 制約検証オブジェクト
  dimension_   % 全断面のdimension配列（初期化時に設定）
  idvar2wfsCell_   % 変数ID→WFS断面リスト {nxvar×1} cell配列
  idvar2hssCell_   % 変数ID→HSS断面リスト {nxvar×1} cell配列
end

properties (Dependent)
  idHgap2var  % 梁せい差評価の変数IDペア [ngap×2]
  idHgap2sec  % 梁せい差評価の断面IDペア [ngap×2]
  dimension   % 全断面のdimension配列（読み取り専用）
end

methods (Static)
  % 静的メソッド（SectionManagerから移行）
  [upsec, dwsec] = findUpDownWfsThick(secwfs, twortf, seclist, options)
  [upsec, dwsec] = findUpDownHssThick(sechss, seclist, options)
  idsec2slist = getSectionListMapping(secdim)
  
  % 並列処理用の静的メソッド
  secdim = findNearestSectionStatic(xvar, options, ...
    idMapper, standardAccessor, dimension, secListAll)
  xvar = findNearestXvarStatic(secdim, options, idMapper)
  
  % 修正版の静的メソッド
  secdim = findNearestSectionStatic_fixed(xvar, options, ...
    idMapper, standardAccessor, dimension, secListAll, ...
    constraintValidator)
end

methods
  %% コンストラクタ
  function obj = SectionNeighborSearcher(idHgap2var, idHgap2sec, ...
    options, idMapper, standardAccessor, constraintValidator, dimension)
  %SectionNeighborSearcher コンストラクタ
  %   obj = SectionNeighborSearcher(idHgap2var, idHgap2sec, options,
  %     idMapper, standardAccessor, constraintValidator, dimension) は、
  %   近傍断面探索オブジェクトを作成します。
  %
  %   入力引数:
  %     idHgap2var - 変数IDペア [ngap×2]
  %     idHgap2sec - 断面IDペア [ngap×2]
  %     options    - オプション構造体
  %                  .reqHgap: 要求梁せい差
  %                  .tolHgap: 許容梁せい差
  %     idMapper   - IDマッピングオブジェクト
  %     standardAccessor - 標準値アクセサオブジェクト
  %     constraintValidator - 制約検証オブジェクト
  %     dimension  - 全断面のdimension配列
  
  % 引数の設定
  obj.idHgap2var_ = idHgap2var;
  obj.idHgap2sec_ = idHgap2sec;
  obj.options = options;
  obj.idMapper_ = idMapper;
  obj.standardAccessor_ = standardAccessor;
  obj.constraintValidator_ = constraintValidator;
  obj.dimension_ = dimension;
  
  % 変数→断面マッピングを事前計算
  obj.computeVariableToSectionMappings();
  
  return
  end
  
  %% Dependentプロパティのgetter
  function val = get.idHgap2var(obj)
    val = obj.idHgap2var_;
  end
  
  function val = get.idHgap2sec(obj)
    val = obj.idHgap2sec_;
  end
  
  function val = get.dimension(obj)
    val = obj.dimension_;
  end
  
  %% 梁せい差計算（変数ベース）
  function [conhgap, Hgap] = calcHeightGapFromVar(obj, xvar)
  %calcHeightGapFromVar 変数から梁せい差を計算
  %   [conhgap, Hgap] = calcHeightGapFromVar(obj, xvar) は、
  %   変数値から梁せい差と制約値を計算します。
  %
  %   入力引数:
  %     xvar - 変数値ベクトル [nvar×1]
  %
  %   出力引数:
  %     conhgap - 制約値 [ngap×1]（1-Hgap/reqHgap）
  %     Hgap    - 梁せい差 [ngap×1]
  
  % 元の関数を呼び出し
  [conhgap, Hgap] = calc_girder_height_gap_var(...
    xvar, obj.idHgap2var, obj.options);
  
  return
  end
  
  %% 梁せい差計算（断面寸法ベース）
  function [conhgapsec, Hgapsec] = ...
    calcHeightGapFromSection(obj, secdim)
  %calcHeightGapFromSection 断面寸法から梁せい差を計算
  %   [conhgapsec, Hgapsec] = calcHeightGapFromSection(obj, secdim) は、
  %   断面寸法から梁せい差と制約値を計算します。
  %
  %   入力引数:
  %     secdim - 断面寸法配列 [nsec×ndim]
  %              第1列が梁せい
  %
  %   出力引数:
  %     conhgapsec - 制約値 [ngap×1]（1-Hgapsec/reqHgap）
  %     Hgapsec    - 梁せい差 [ngap×1]
  
  % 元の関数を呼び出し
  [conhgapsec, Hgapsec] = calc_girder_height_gap_section(...
    secdim, obj.idHgap2sec, obj.options);
  
  return
  end
  
end

methods (Access = private)
  %% 変数→断面マッピングの事前計算
  function computeVariableToSectionMappings(obj)
  %computeVariableToSectionMappings 変数→断面マッピングを事前計算
  %   各変数IDに対応するWFS/HSS断面リストを事前計算し、
  %   idvar2wfsCell_およびidvar2hssCell_に格納します。
  
  % 初期化
  nxvar = obj.idMapper_.nxvar;
  obj.idvar2wfsCell_ = cell(nxvar, 1);
  obj.idvar2hssCell_ = cell(nxvar, 1);
  
  % 断面情報取得
  idsec2var = obj.idMapper_.idsec2var;
  idsec2stype = obj.idMapper_.idsec2stype;
  
  % WFS断面の変数マッピング
  isWfs = (idsec2stype == PRM.WFS);
  if any(isWfs)
    % WFS断面の寸法インデックス範囲
    WFS_DIM_RANGE = PRM.SECDIM_WFS_H:PRM.SECDIM_WFS_TF;
    idwfs2x = idsec2var(isWfs, WFS_DIM_RANGE);  % H, B, tw, tf
    idwfs2repwfs = obj.idMapper_.idwfs2repwfs;
    idrepwfs2wfs = obj.idMapper_.idrepwfs2wfs;
    
    % 各次元について処理
    for idim = WFS_DIM_RANGE
      uniqueVars = unique(idwfs2x(:, idim));
      for i = 1:length(uniqueVars)
        idvar = uniqueVars(i);
        if idvar > 0 && idvar <= nxvar
          % この変数IDに対応するWFS断面を計算
          idwfs = unique(idrepwfs2wfs(...
            idwfs2repwfs(idwfs2x(:,idim) == idvar)));
          obj.idvar2wfsCell_{idvar} = idwfs;
        end
      end
    end
  end
  
  % HSS断面の変数マッピング
  isHss = (idsec2stype == PRM.HSS);
  if any(isHss)
    % HSS断面の寸法インデックス範囲
    HSS_DIM_RANGE = PRM.SECDIM_HSS_D:PRM.SECDIM_HSS_T;
    idhss2x = idsec2var(isHss, HSS_DIM_RANGE);  % D, t
    idhss2rephss = obj.idMapper_.idhss2rephss;
    idrephss2hss = obj.idMapper_.idrephss2hss;
    
    % 各次元について処理
    for idim = HSS_DIM_RANGE
      uniqueVars = unique(idhss2x(:, idim));
      for i = 1:length(uniqueVars)
        idvar = uniqueVars(i);
        if idvar > 0 && idvar <= nxvar
          % この変数IDに対応するHSS断面を計算
          idhss = unique(idrephss2hss(...
            idhss2rephss(idhss2x(:,idim) == idvar)));
          obj.idvar2hssCell_{idvar} = idhss;
        end
      end
    end
  end
  
  return
  end
end

end