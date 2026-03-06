function [weight, cost, idsec, idmat] = ...
  calc_steel_cost_brace(brace, ...
    idsecb2sec, secdim, lm, Am, secmgr)
%calc_steel_cost_brace - 鉛直ブレースの鉄骨積算データを算出
%
%   [weight, cost, idsec, idmat] =
%     calc_steel_cost_brace(brace,
%     idsecb2sec, secdim, lm, Am, secmgr)
%   は、鉛直ブレースの要素単位の鉄骨積算データを
%   算出する。SS7積算マニュアル 4.4.5「鉛直ブレース」
%   に対応。引張ブレース(TB)を含む。
%   メーカー製品(4.4.6)は対象外。
%
%   入力引数:
%     brace      - ブレース部材構造体
%     idsecb2sec - ブレース断面→統合断面ID変換配列
%     secdim     - 断面寸法配列 [nsec×ncol]
%     lm         - 部材長 [nm×1] (mm)
%     Am         - 断面積 [nm×1] (mm2)
%     secmgr     - SectionManager
%
%   出力引数:
%     weight - 鉄骨重量 [nb×1] (t)
%     cost   - コスト [nb×1] (t相当)
%     idsec  - 統合断面ID [nb×1]
%     idmat  - 材料ID [nb×1]

nb = numel(brace.idme);
weight = zeros(nb, 1);
cost = zeros(nb, 1);
idsec = zeros(nb, 1);
idmat = zeros(nb, 1);

for ib = 1:nb
  idsb = brace.idsecb(ib);
  is = idsecb2sec(idsb);
  idm = brace.idme(ib);
  idslist = secdim(is, 6);
  idsection = secdim(is, 7);
  cfm = secmgr.secList.cost_factor{idslist}(idsection);

  idsec(ib) = is;
  idmat(ib) = secmgr.secList.idmaterial{idslist}(idsection);
  weight(ib) = Am(idm) * lm(idm) * PRM.RHOS * 1e-9;
  cost(ib) = cfm * weight(ib);
end

return
end
