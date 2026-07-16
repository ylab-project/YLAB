function [conjbs, jbsratio, idjbs] = calc_joint_bearing_strength( ...
  secdim, Zpy, Fm, steel_grade, com, options)
%calc_joint_bearing_strength - 仕口制約を名目梁単位で計算する
%
%   [conjbs, jbsratio, idjbs] = ...
%     calc_joint_bearing_strength( ...
%     secdim, Zpy, Fm, steel_grade, com, options) は、候補断面の
%   断面性能と材料情報から名目梁端ごとの保有耐力接合を計算する。
%
%   入力引数:
%     secdim - 断面寸法
%     Zpy - 部材ごとの塑性断面係数
%     Fm - 部材ごとの基準強度
%     steel_grade - 部材ごとの鋼種
%     com - 共通構造体
%     options - 共通オプション
%
%   出力引数:
%     conjbs - 保有耐力接合の制約値
%     jbsratio - 名目梁端ごとの仕口耐力比
%     idjbs - 制約値に対応する名目梁端番号

idm2s = com.member.property.idsec;
idmc2m = com.member.column.idme;
isjbs = com.exclusion.is_joint_bearing_strength;
girder = com.member.girder;
idmeg = com.nominal.girder.idmeg;

% 名目梁端の節点と代表部材を通常解析と同じ対応で取得する
[ng_node1, ng_node2] = get_nominal_girder_end_nodes(girder, idmeg);
idm_ng = girder.idme(idmeg(:, 1));
sdimg_ng = secdim(idm2s(idm_ng), 1:4);
Zpyg_ng = Zpy(idm_ng);
Fg_ng = Fm(idm_ng);
grade_ng = steel_grade(idm_ng);
Fcol = Fm(idmc2m);

if options.jbs_mu_formula == PRM.JBS_AIJ
  % AIJ式では候補柱断面から梁端ごとのmファクター分子を求める
  secdim_col = secdim(idm2s(idmc2m), :);
  m_num_col = calc_col_dim_jbs(com.member, secdim_col, Fcol, ...
    ng_node1, ng_node2);
  [conjbs, jbsratio, idjbs] = calc_joint_bearing_strength_aij( ...
    sdimg_ng, Zpyg_ng, Fg_ng, grade_ng, m_num_col, isjbs, options);
else
  % 基準式では柱基準強度から梁端ごとの終局強度を求める
  sigu_col = calc_sigu_col(com.member, Fcol, ng_node1, ng_node2);
  [conjbs, jbsratio, idjbs] = calc_joint_bearing_strength_std( ...
    sdimg_ng, Zpyg_ng, Fg_ng, grade_ng, sigu_col, isjbs, options);
end

return
end