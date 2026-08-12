function weight = calc_element_load_weight(element_load, cxl, cyl, ...
  idm2n, nnode)
%calc_element_load_weight - 分類済み要素荷重を節点重量へ変換する
%
%   weight = calc_element_load_weight(element_load, cxl, cyl, idm2n,
%     nnode) は、要素座標系で入力された重量用固定端力を全体座標系の
%   節点力へ変換し、case・type別の重量プールを返す。
%
%   入力引数:
%     element_load - 要素荷重の読込結果
%     cxl,cyl      - 部材座標系の方向余弦
%     idm2n        - 部材から節点への対応 [nme×2]
%     nnode        - 節点数
%
%   出力引数:
%     weight - 分類別節点力、解析用節点力および地震重量有無
%
%   備考:
%     - 正の全体Z方向力を正の重量寄与として保持する。
%     - case=EX/EY は完成済みの地震用重量として独立に保持する。

ncase = size(element_load.weight_ar, 3);
ntype = size(element_load.weight_ar, 4);
weight.nodal = zeros(nnode, 6, ncase, ntype);
for icase = 1:ncase
  for itype = 1:ntype
    ar = element_load.weight_ar(:, :, icase, itype);
    weight.nodal(:, :, icase, itype) = update_felement( ...
      ar, cxl, cyl, idm2n, nnode, 1);
  end
end

nlc = size(element_load.analysis_ar, 3);
weight.analysis_felement = update_felement(element_load.analysis_ar, ...
  cxl, cyl, idm2n, nnode, nlc);
weight.has_new_input = element_load.has_input;
exey = element_load.weight_ar(:, :, PRM.ELOAD_CASE_EXEY, :);
weight.has_seismic = any(exey ~= 0, 'all');

return
end
