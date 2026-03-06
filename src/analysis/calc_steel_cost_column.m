function [weight, cost, idsec, idmat] = ...
  calc_steel_cost_column(column, stype, ...
    idsecc2sec, secdim, lm, Am, secmgr)
%calc_steel_cost_column - 柱の鉄骨積算データを算出
%
%   [weight, cost, idsec, idmat] =
%     calc_steel_cost_column(column, stype,
%     idsecc2sec, secdim, lm, Am, secmgr)
%   は、柱の要素単位の鉄骨積算データを算出する。
%   仕口部を含む1要素あたりの合計重量を返す。
%   スキップ対象(BRACE_FOUNDATION, RCRS)は0。
%
%   入力引数:
%     column     - 柱部材構造体
%     stype      - 断面タイプ配列
%     idsecc2sec - 柱断面→統合断面ID変換配列
%     secdim     - 断面寸法配列 [nsec×ncol]
%     lm         - 部材長 [nm×1] (mm)
%     Am         - 断面積 [nm×1] (mm2)
%     secmgr     - SectionManager
%
%   出力引数:
%     weight - 鉄骨重量 [nc×1] (t)
%     cost   - コスト [nc×1] (t相当)
%     idsec  - 統合断面ID [nc×1]
%     idmat  - 材料ID [nc×1]

nc = numel(column.idme);
weight = zeros(nc, 1);
cost = zeros(nc, 1);
idsec = zeros(nc, 1);
idmat = zeros(nc, 1);

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
  idslist = secdim(is, 6);
  idsection = secdim(is, 7);
  cfm = secmgr.secList.cost_factor{idslist}(idsection);

  idsec(ic) = is;
  idmat(ic) = ...
    secmgr.secList.idmaterial{idslist}(idsection);
  weight(ic) = Am(idm) * lm(idm) * PRM.RHOS * 1e-9;
  cost(ic) = cfm * weight(ic);
end

return
end
