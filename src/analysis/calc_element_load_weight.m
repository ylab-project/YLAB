function [weight, girder_self] = calc_element_load_weight( ...
  element_force, nodal_force, girder_ar, cxl, cyl, lm, idm2n, nnode)
%calc_element_load_weight - 共通荷重テーブルを重量プールへ変換する
%
%   [weight, girder_self] = calc_element_load_weight(element_force,
%   nodal_force, girder_ar, cxl, cyl, lm, idm2n, nnode) は、線材荷重の
%   全体Z方向成分と節点荷重の全体Z軸下向き成分を、用途・区分・
%   タイプ別の節点重量プールへ加算する。線材荷重は解析用arへ合力
%   する前に用途・区分・タイプ別の完全な端部力をまとめ、梁自重と
%   ともに合力とモーメントから静力学的に等価な端部重量を求める。
%
%   入力引数:
%     element_force - 共通内部データの線材荷重テーブル
%     nodal_force   - 共通内部データの節点荷重テーブル
%     girder_ar     - 梁自重による要素座標系端部力 [nme×12]
%     cxl,cyl       - 部材座標系の方向余弦
%     lm            - 部材長 [nme×1]
%     idm2n         - 部材から節点への対応 [nme×2]
%     nnode         - 節点数
%
%   出力引数:
%     weight       - 節点別の重量プール
%     girder_self  - 梁自重の物理的な節点配分 [nnode×1]
%
%   備考:
%     - poolの軸は節点×用途×区分×タイプで、単位はNである。
%     - 線材荷重は全体Z方向正、節点荷重は-Fzを正の重量とする。
%     - 水平投影長が0の部材は、入力された鉛直端部力を維持する。

% 用途・区分は1からの連番IDで、最大値が種類数になる（PRM）
nusage = PRM.WUSAGE_SEISMIC;
nclass = PRM.WCLASS_DIRECT;
ntype = length(PRM.WTYPE_NAMES);
nme = size(idm2n, 1);
weight_ar = zeros(nme, 12, nusage, nclass, ntype);
weight.pool = zeros(nnode, nusage, nclass, ntype);
weight.cantilever_pool = zeros(nnode, nusage, nclass, ntype);
girder_self = calc_element_nodal_weight(girder_ar, cxl, cyl, lm, ...
  idm2n, nnode);

element_usage = element_force.wusage;
element_class = element_force.wclass;
element_type = element_force.wtype;
element_idme = element_force.idme;
element_ar = element_force.ar;
for k = 1:length(element_idme)
  wusage = element_usage(k);
  wclass = element_class(k);
  wtype = element_type(k);
  if wusage == 0 || wclass == 0 || wtype == 0
    continue
  end
  idme = element_idme(k);
  group_ar = weight_ar(idme, :, wusage, wclass, wtype);
  weight_ar(idme, :, wusage, wclass, wtype) = group_ar + element_ar(k, :);
end

% 解析用arへ合力する前に、分類ごとの線材荷重を節点重量へ変換する
for wusage = 1:nusage
  for wclass = 1:nclass
    for wtype = 1:ntype
      ar = reshape(weight_ar(:, :, wusage, wclass, wtype), nme, 12);
      if ~any(ar, 'all')
        continue
      end
      nodal = calc_element_nodal_weight(ar, cxl, cyl, lm, idm2n, nnode);
      weight.pool(:, wusage, wclass, wtype) = nodal;
    end
  end
end

nodal_usage = nodal_force.wusage;
nodal_class = nodal_force.wclass;
nodal_type = nodal_force.wtype;
nodal_idnode = nodal_force.idnode;
nodal_f = nodal_force.f;
nodal_is_cantilever = nodal_force.is_cantilever;
for k = 1:length(nodal_idnode)
  wusage = nodal_usage(k);
  wclass = nodal_class(k);
  wtype = nodal_type(k);
  if wusage == 0 || wclass == 0 || wtype == 0
    continue
  end
  idnode = nodal_idnode(k);
  value = -nodal_f(k, 3);
  group_value = weight.pool(idnode, wusage, wclass, wtype);
  weight.pool(idnode, wusage, wclass, wtype) = group_value + value;
  if nodal_is_cantilever(k)
    weight.cantilever_pool(idnode, wusage, wclass, wtype) = ...
      weight.cantilever_pool(idnode, wusage, wclass, wtype) + value;
  end
end

return
end


function nodal = calc_element_nodal_weight(ar, cxl, cyl, lm, idm2n, nnode)
%calc_element_nodal_weight - 完全な端部力から節点重量を算出する
%
%   nodal = calc_element_nodal_weight(ar, cxl, cyl, lm, idm2n, nnode)
%   は、部材ごとの鉛直合力と全モーメントから静力学的に等価な
%   両端重量を求め、節点ごとに加算する。
%
%   入力引数:
%     ar      - 要素座標系の端部力 [nme×12]
%     cxl,cyl - 部材座標系の方向余弦
%     lm      - 部材長 [nme×1]
%     idm2n   - 部材から節点への対応 [nme×2]
%     nnode   - 節点数
%
%   出力引数:
%     nodal - 節点別重量 [nnode×1]
nme = size(ar, 1);
czl = cross(cxl, cyl, 2);
member_weight = zeros(nme, 2);
vertical = [0; 0; 1];
for idme = 1:nme
  if ~any(ar(idme, :))
    continue
  end
  arunit = ar(idme, :)';
  tt = [cxl(idme, :)' cyl(idme, :)' czl(idme, :)'];
  f_i = [tt * arunit(1:3); tt * arunit(4:6)];
  f_j = [tt * arunit(7:9); tt * arunit(10:12)];
  r = lm(idme) * cxl(idme, :)';
  moment_axis = cross(r, vertical);
  axis_norm2 = dot(moment_axis, moment_axis);
  if axis_norm2 == 0
    member_weight(idme, :) = [f_i(3), f_j(3)];
    continue
  end
  total_moment = f_i(4:6) + f_j(4:6) + cross(r, f_j(1:3));
  member_weight(idme, 2) = dot(total_moment, moment_axis) / axis_norm2;
  member_weight(idme, 1) = f_i(3) + f_j(3) - member_weight(idme, 2);
end
nodal = accumarray(idm2n(:), member_weight(:), [nnode, 1]);

return
end
