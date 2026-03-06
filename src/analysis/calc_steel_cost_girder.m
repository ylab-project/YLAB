function [weight, cost, idsec, idmat] = ...
  calc_steel_cost_girder(girder, stype, ...
    idsecg2sec, secdim, lm, Am, secmgr)
%calc_steel_cost_girder - 大梁の鉄骨積算データを算出
%
%   [weight, cost, idsec, idmat] =
%     calc_steel_cost_girder(girder, stype,
%     idsecg2sec, secdim, lm, Am, secmgr)
%   は、大梁の要素単位の鉄骨積算データを算出する。
%   スキップ対象(RCRS)は0。
%
%   入力引数:
%     girder     - 梁部材構造体
%     stype      - 断面タイプ配列
%     idsecg2sec - 梁断面→統合断面ID変換配列
%     secdim     - 断面寸法配列 [nsec×ncol]
%     lm         - 部材長 [nm×1] (mm)
%     Am         - 断面積 [nm×1] (mm2)
%     secmgr     - SectionManager
%
%   出力引数:
%     weight - 鉄骨重量 [ng×1] (t)
%     cost   - コスト [ng×1] (t相当)
%     idsec  - 統合断面ID [ng×1]
%     idmat  - 材料ID [ng×1]

ng = numel(girder.idme);
weight = zeros(ng, 1);
cost = zeros(ng, 1);
idsec = zeros(ng, 1);
idmat = zeros(ng, 1);

for ig = 1:ng
  idsg = girder.idsecg(ig);
  is = idsecg2sec(idsg);
  if stype(is) == PRM.RCRS
    continue
  end

  idm = girder.idme(ig);
  idslist = secdim(is, 6);
  idsection = secdim(is, 7);
  cfm = secmgr.secList.cost_factor{idslist}(idsection);

  idsec(ig) = is;
  idmat(ig) = ...
    secmgr.secList.idmaterial{idslist}(idsection);
  weight(ig) = Am(idm) * lm(idm) * PRM.RHOS * 1e-9;
  cost(ig) = cfm * weight(ig);
end

return
end
