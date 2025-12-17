classdef SectionStandardAccessor < handle
% SectionStandardAccessor - 断面規格値アクセサークラス
%
% 断面リストから各寸法の規格値（標準値・公称値）を取得する
% 専門クラス。SectionConstraintValidatorから断面規格値取得
% 機能を分離して作成。
%
% 用語の定義:
%   - Standard値（規格実寸法）: 規格で定められた実際の
%     寸法値（例：398mm）
%   - Nominal値（公称値）: 丸められた呼び寸法（例：H400）
%   - SectionDimension: (H, B, tw, tf)の組み合わせで
%     特定の断面を定義
%
% Properties:
%   idPhase - 現在のフェーズID (デフォルト: 999)
%
% Methods:
%   getNominalH - H形鋼のH公称値取得
%   getNominalB - H形鋼のB公称値取得
%   getStandardTw - H形鋼のtw規格値取得
%   getStandardTf - H形鋼のtf規格値取得
%   getStandardD - HSS断面のD規格値取得
%   getStandardT - HSS断面のt規格値取得
%   getStandardV1 - BRB断面のV1規格値取得
%   getStandardV2 - BRB断面のV2規格値取得
%
% 使用例:
%   accessor = SectionStandardAccessor(secList);
%   accessor.idPhase = 1;
%   hValues = accessor.getNominalH(idsList);

properties (Access = private)
  secList_   % SectionListHandlerへの参照
  idMapper_  % IdMapperへの参照
  idPhase_   % 現在のフェーズID (デフォルト: 999)
end

properties (Dependent)
  idPhase    % フェーズIDのgetter/setter
  nlist      % 断面リスト数（読み取り専用）
end

methods
  %% SectionStandardAccessor
  function obj = SectionStandardAccessor(secList, idMapper)
    % コンストラクタ
    %
    % 入力:
    %   secList - SectionListHandlerオブジェクト（必須）
    %   idMapper - IdMapperオブジェクト（getStandardValuesで必要）
    
    if nargin < 1
      error('SectionStandardAccessor:InvalidArgs', ...
        'SectionListHandlerオブジェクトが必要です');
    end
    
    obj.secList_ = secList;
    if nargin >= 2
      obj.idMapper_ = idMapper;
    end
    obj.idPhase_ = 999;  % デフォルト値
    return
  end
  
  %% get.idPhase
  function idPhase = get.idPhase(obj)
    % フェーズIDのgetter
    idPhase = obj.idPhase_;
  end
  
  %% set.idPhase
  function set.idPhase(obj, idPhase)
    % フェーズIDのsetter
    %
    % 入力:
    %   idPhase - フェーズID（0以上の数値）
    
    if ~isnumeric(idPhase) || idPhase < 0
      error('SectionStandardAccessor:InvalidIdPhase', ...
        '有効なフェーズID（0以上の数値）が必要です');
    end
    obj.idPhase_ = idPhase;
    return
  end
  
  %% get.nlist
  function val = get.nlist(obj)
    % 断面リスト数を取得
    %
    % 出力:
    %   val - 断面リスト数（スカラー整数）
    
    val = obj.secList_.nlist;
    return
  end
end
end