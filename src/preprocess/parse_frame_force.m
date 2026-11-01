function com = parse_frame_force(com)
%parse_frame_force - 荷重の作用先を解決し解析用配列を生成する
%
%   com = parse_frame_force(com) は、初期解析モデルへ入力荷重を
%   対応付け、片持梁と地震力作用位置による荷重を計算する。
%   解決済み荷重表と解析用配列を生成し、一時入力を削除する。
%
%   入力引数:
%     com - 初期解析モデルと正規化したcom.force.inputを持つ共通データ
%
%   出力引数:
%     com - 解決済み荷重表とケース別の解析用配列を持つ共通データ

force_input = com.force.input;
issues = force_input.issues;
fnode = parse_legacy_nodal_force_block(force_input.legacy_nodal, com);
fnode = add_earthquake_force_position_mz( ...
  force_input.earthquake_position, com, fnode);
[com.faddnode, com.faddnode_report_excl] = ...
  parse_additive_nodal_force_block(force_input.additive_nodal, com);
com.force.legacy_element = ...
  parse_legacy_girder_force_block(force_input.legacy_element, com);
[com.force.element, issues] = parse_element_force_block( ...
  force_input.element, com, issues);
[nodal_force, issues] = parse_nodal_force_block(force_input.nodal, ...
  com, issues);
[cantilever_force, issues] = parse_cantilever_force_block( ...
  force_input.cantilever, force_input.cantilever_placement, com, issues);
com.force.nodal = [nodal_force; cantilever_force];
report_input_issues(issues, com.force.element, com.force.nodal);

[ar, M0] = calc_element_force_ar(com.force.legacy_element, com.nme, ...
  com.nlc);
[ar_element, M0_element] = calc_element_force_ar(com.force.element, ...
  com.nme, com.nlc);
fnode_nodal = calc_nodal_force_fnode(com.force.nodal, com.nnode, com.nlc);
com.force.legacy_fnode = fnode;
com.fnode = fnode + fnode_nodal;
com.ar = ar + ar_element;
com.M0 = M0 + M0_element;
com.force = rmfield(com.force, 'input');

return
end


function [fnode, fnode_excl] = ...
  parse_additive_nodal_force_block(nodal_force, com)
%parse_additive_nodal_force_block - 追加節点荷重を加算し非計上分を分ける
%
%   [fnode, fnode_excl] = parse_additive_nodal_force_block( ...
%     nodal_force, com) は、同一節点・ケースの入力を順に加算する。
%   2回目以降の荷重は解析へ加え、帳票では非計上分として分離する。
%
%   入力引数:
%     nodal_force - 配置指定・ケース・6成分を持つ荷重テーブル
%     com         - 基準線と節点、荷重ケースを持つ解析モデル
%
%   出力引数:
%     fnode      - 追加節点荷重の全量 [nnode×6×nlc]
%     fnode_excl - 追加節点荷重の帳票非計上分 [nnode×6×nlc]

fnode = zeros(com.nnode, 6, com.nlc);
fnode_excl = zeros(com.nnode, 6, com.nlc);
seen = false(com.nnode, com.nlc);
node = com.node;
for ir = 1:height(nodal_force)
  names = nodal_force.selector(ir, :);
  idx = find(matches(com.baseline.x.name, names{2}));
  idy = find(matches(com.baseline.y.name, names{3}));
  idz = find(matches(com.baseline.z.name, names{1}));
  in = find(node.idx == idx & node.idy == idy & node.idz == idz);
  lc = nodal_force.ilc(ir);
  fadd = nodal_force.f(ir, :);
  fnode(in, :, lc) = fnode(in, :, lc) + fadd;
  if seen(in, lc)
    fnode_excl(in, :, lc) = fnode_excl(in, :, lc) + fadd;
  else
    seen(in, lc) = true;
  end
end

return
end

function fnode = add_earthquake_force_position_mz(position, com, fnode)
%add_earthquake_force_position_mz - 地震力の偏心による荷重を加える
%
%   fnode = add_earthquake_force_position_mz(position, com, fnode) は、
%   地震力の作用位置によるねじり荷重を加える。
%
%   入力引数:
%     position - 検証済みの階指定と作用位置座標のテーブル
%     com - 架構・断面・材料を含む共通データ
%     fnode - 節点の方向別・ケース別荷重
%
%   出力引数:
%     fnode - 節点の方向別・ケース別荷重

if isempty(position)
  return
end

node = com.node;
story = com.story;
loadcase = com.loadcase;
used = false(com.nstory, 1);
for ir = 1:height(position)
  i = position.irow(ir);
  floor_name = position.selector{ir};
  ist = find(matches(story.floor_name, floor_name), 1);
  if isempty(ist)
    ist = find(matches(story.name, floor_name), 1);
  end
  if isempty(ist)
    error('YLAB:Input:EarthquakeForcePositionStoryNotFound', ...
      '地震力作用位置の階が見つかりません（行 %d: %s）', i, floor_name);
  end
  if used(ist)
    error('YLAB:Input:DuplicateEarthquakeForcePosition', ...
      '地震力作用位置が同じ層に複数指定されています（行 %d）', i);
  end
  used(ist) = true;

  idnode = story.idnoderep(ist);
  if isnan(idnode)
    error('YLAB:Input:EarthquakeForcePositionNodeNotFound', ...
      '地震力作用位置を反映する代表節点が見つかりません（行 %d）', i);
  end
  posx = position.x(ir);
  posy = position.y(ir);
  for ilc=1:com.nlc
    lcdir = loadcase.dir(ilc);
    if lcdir ~= PRM.EXP && lcdir ~= PRM.EXN && lcdir ~= PRM.EYP && ...
        lcdir ~= PRM.EYN
      continue
    end
    isnode = node.idstory == ist;
    fx = sum(fnode(isnode, 1, ilc));
    fy = sum(fnode(isnode, 2, ilc));
    mz = fx * (story.yg(ist) - posy) + fy * (posx - story.xg(ist));
    fnode(idnode, 6, ilc) = fnode(idnode, 6, ilc) + mz;
  end
end

return
end
