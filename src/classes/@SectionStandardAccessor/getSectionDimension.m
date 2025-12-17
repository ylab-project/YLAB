function dimension = getSectionDimension(obj, idList, idPhase)
%getSectionDimension 断面寸法配列を取得
%   dimension = getSectionDimension(obj, idList, idPhase) は、
%   指定された断面リストの寸法配列を取得します。
%
%   入力引数:
%     idList  - 断面リストID (スカラー整数)
%     idPhase - フェーズID (スカラー整数、省略可能)
%               省略時はobj.idPhase_を使用
%
%   出力引数:
%     dimension - 断面寸法配列
%                 WFS: [n×7] (H,B,tw,tf,r,Aw,Af)
%                 HSS: [n×3] (D,t,r)
%                 BRB: [n×4] (V1,V2,index,materialId)
%                 RCRS: 断面タイプに依存
%
%   例:
%     dim = accessor.getSectionDimension(1);
%     dim = accessor.getSectionDimension(2, 999);
%
%   参考:
%     SectionListHandler.getDimension

% 引数の検証
if nargin < 2
  error('SectionStandardAccessor:InvalidArgs', ...
    '断面リストIDが必要です');
end

% idPhaseの設定
if nargin < 3
  idPhase = obj.idPhase_;
end

% SectionListHandlerのgetDimensionを呼び出し
dimension = obj.secList_.getDimension(idList, idPhase);

return
end