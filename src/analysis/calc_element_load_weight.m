function weight = calc_element_load_weight(element_force, nodal_force, ...
  cxl, cyl, idm2n, nnode)
%calc_element_load_weight - 共通荷重テーブルを重量プールへ変換する
%
%   weight = calc_element_load_weight(element_force, nodal_force,
%   cxl, cyl, idm2n, nnode) は、線材荷重の全体Z方向成分と節点荷重の
%   全体Z軸下向き成分を、用途・区分・タイプ別の節点重量プールへ
%   加算する。
%
%   入力引数:
%     element_force - 共通内部データの線材荷重テーブル
%     nodal_force   - 共通内部データの節点荷重テーブル
%     cxl,cyl       - 部材座標系の方向余弦
%     idm2n         - 部材から節点への対応 [nme×2]
%     nnode         - 節点数
%
%   出力引数:
%     weight - 節点別の重量プール
%
%   備考:
%     - poolの軸は節点×用途×区分×タイプで、単位はNである。
%     - 線材荷重は全体Z方向正、節点荷重は-Fzを正の重量とする。

% 用途・区分は1からの連番IDで、最大値が種類数になる（PRM）
nusage = PRM.WUSAGE_SEISMIC;
nclass = PRM.WCLASS_DIRECT;
ntype = length(PRM.WTYPE_NAMES);
nme = size(idm2n, 1);
weight_ar = zeros(nme, 12, nusage, nclass, ntype);
weight.pool = zeros(nnode, nusage, nclass, ntype);
weight.cantilever_pool = zeros(nnode, nusage, nclass, ntype);

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

% 線材荷重がある組合せだけを節点重量へ変換する
for wusage = 1:nusage
  for wclass = 1:nclass
    for wtype = 1:ntype
      ar = reshape(weight_ar(:, :, wusage, wclass, wtype), nme, 12);
      if ~any(ar, 'all')
        continue
      end
      nodal = update_felement(ar, cxl, cyl, idm2n, nnode, 1);
      weight.pool(:, wusage, wclass, wtype) = nodal(:, 3, 1);
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
