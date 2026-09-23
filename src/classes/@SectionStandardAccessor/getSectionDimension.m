function [dimension, idsection] = getSectionDimension(obj, idList, idPhase)
%getSectionDimension 断面寸法配列を取得
%   dimension = getSectionDimension(obj, idList, idPhase) は、
%   指定された断面リストの寸法配列を取得します。
%   [dimension, idsection] = getSectionDimension(...) は、各行に
%   対応する候補断面表の行番号もあわせて返します。
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
%     idsection - 候補断面表の行番号 [n×1]
%
%   例:
%     dim = accessor.getSectionDimension(1);
%     dim = accessor.getSectionDimension(2, 999);
%
%   参考:
%     SectionListHandler.getDimension

% 引数の検証
if nargin < 2
  error('SectionStandardAccessor:InvalidArgs', '断面リストIDが必要です');
end

% 省略時は現在フェーズ。寸法だけなら保存値を返す
if nargin < 3
  if nargout < 2
    dimension = obj.currentSectionDimensionCell_{idList};
    return
  end
  idPhase = obj.idPhase_;
end

% 寸法と候補断面表の行番号を同じフェーズ絞込みから取り出す
[dimension, idsection] = obj.secList_.getDimension(idList, idPhase);

return
end
