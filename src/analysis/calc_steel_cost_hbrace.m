function [weight, cost, idsec, idmat] = ...
  calc_steel_cost_hbrace(hbrace, ...
    idsechb2sec, secdim, lm, Am, secmgr)
%calc_steel_cost_hbrace - 水平ブレースの鉄骨積算データを算出
%
%   [weight, cost, idsec, idmat] =
%     calc_steel_cost_hbrace(hbrace,
%     idsechb2sec, secdim, lm, Am, secmgr)
%   は、水平ブレースの要素単位の鉄骨積算データを
%   算出する。
%
%   入力引数:
%     hbrace     - 水平ブレース部材構造体
%     idsechb2sec - 水平ブレース断面→統合断面ID変換
%     secdim     - 断面寸法配列 [nsec×ncol]
%     lm         - 積算用部材長 [nhb×1] (mm)
%     Am         - 断面積 [nm×1] (mm2)
%     secmgr     - SectionManager
%
%   出力引数:
%     weight - 鉄骨重量 [n×1] (t)
%     cost   - コスト [n×1] (t相当)
%     idsec  - 統合断面ID [n×1]
%     idmat  - 材料ID [n×1]

nhb = numel(hbrace.idme);

% 事前確保
weight = zeros(nhb, 1);
cost = zeros(nhb, 1);
idsec = zeros(nhb, 1);
idmat = zeros(nhb, 1);

for ib = 1:nhb
  isb = hbrace.idsechb(ib);
  is = idsechb2sec(isb);

  idm = hbrace.idme(ib);
  L_mm = lm(ib);

  idslist = secdim(is, 6);
  idsection = secdim(is, 7);
  if idslist == 0 || idsection == 0
    continue
  end
  cfm = secmgr.secList.cost_factor{idslist}(idsection);

  idsec(ib) = is;
  idmat(ib) = ...
    secmgr.secList.idmaterial{idslist}(idsection);
  weight(ib) = Am(idm) * L_mm * PRM.RHOS * 1e-9;
  cost(ib) = cfm * weight(ib);
end

return
end
