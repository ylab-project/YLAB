function [W_jt, W_jb] = ...
  calc_steel_cost_column_joint(column, ...
    girder, node, stype, idsecg2sec, ...
    idsecc2sec, secdim, Am, cxl_girder)
%calc_steel_cost_column_joint - 柱仕口部の重量を算出
%
%   [W_jt, W_jb] =
%     calc_steel_cost_column_joint(column,
%     girder, node, stype, idsecg2sec,
%     idsecc2sec, secdim, Am, cxl_girder)
%   は、柱の仕口部(柱頭・柱脚)重量を要素単位で
%   算出する。スキップ対象は0。
%
%   下階に柱がある場合 W_jb=0 とする（下階柱の
%   柱頭仕口で計上済みのため）。
%   本体重量 = weight(ic) - W_jt(ic) - W_jb(ic)。
%
%   入力引数:
%     column     - 柱部材構造体
%     girder     - 梁部材構造体
%     node       - 節点構造体
%     stype      - 断面タイプ配列
%     idsecg2sec - 梁断面→統合断面ID変換配列
%     idsecc2sec - 柱断面→統合断面ID変換配列
%     secdim     - 断面寸法配列 [nsec×ncol]
%     Am         - 断面積 [nm×1] (mm2)
%     cxl_girder - 標準系の梁軸方向余弦 [nmg×3]
%
%   出力引数:
%     W_jt - 仕口部(柱頭)重量 [nc×1] (t)
%     W_jb - 仕口部(柱脚)重量 [nc×1] (t)

nc = numel(column.idme);

% 仕口部長さの算出
if nargin < 9
  cxl_girder = [];
end
[jt, jb] = calc_column_joint_length( ...
  column, girder, node, ...
  stype, idsecg2sec, secdim, cxl_girder);

% 下階柱の有無（柱脚仕口の出力判定用）
has_col_below = ismember(column.idnode1, column.idnode2);

% 仕口部重量
W_jt = zeros(nc, 1);
W_jb = zeros(nc, 1);

for ic = 1:nc
  if column.type(ic) == PRM.COLUMN_FOR_BRACE_FOUNDATION
    continue
  end
  idsc = column.idsecc(ic);
  is = idsecc2sec(idsc);
  if stype(is) == PRM.RCRS
    continue
  end

  idm = column.idme(ic);
  W_jt(ic) = Am(idm) * jt(ic) * PRM.RHOS * 1e-9;
  if ~has_col_below(ic)
    W_jb(ic) = Am(idm) * jb(ic) * PRM.RHOS * 1e-9;
  end
end

return
end
