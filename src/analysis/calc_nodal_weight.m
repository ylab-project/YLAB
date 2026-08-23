function weight = calc_nodal_weight(com, sw, cxl, cyl, idm2n)
%calc_nodal_weight - 用途別の節点重量と帳票用物理量を計算する
%
%   weight = calc_nodal_weight(com, sw, cxl, cyl, idm2n) は、新形式
%   荷重、旧入力、自動計算自重および節点外力を節点重量へ統合する。
%   Kブレース中間節点の再配分、基礎重量判定および累計もここで確定し、
%   writerへ計算済み物理量を渡す（内部設計8・9章）。旧入力の寄与は
%   合算値から差し引かず、入力境界で分けた旧形式データから直接
%   求める。
%
%   入力引数:
%     com     - 節点、部材、荷重および支持情報を持つ共通オブジェクト
%     sw      - 自動計算した柱・梁・壁の節点自重
%     cxl,cyl - 部材座標系の方向余弦
%     idm2n   - 部材から節点への対応 [nme×2]
%
%   出力引数:
%     weight - 分類済み重量と節点別・層別重量
nnode = com.nnode;
raw = calc_element_load_weight(com.force.element, com.force.nodal, ...
  cxl, cyl, idm2n, nnode);
ilc_gp = find_ilc_long_term(com.loadcase);

% 長期ケースがない入力では旧入力を解析非計上として扱う
legacy_floor = zeros(nnode, 1);
legacy_nodal = zeros(nnode, 6);
if ilc_gp > 0
  [legacy_ar, ~] = calc_element_force_ar(com.force.legacy_element, ...
    size(idm2n, 1), com.nlc);
  legacy_element = update_felement(legacy_ar(:, :, ilc_gp), cxl, cyl, ...
    idm2n, nnode, 1);
  legacy_floor = legacy_element(:, 3);
  legacy_nodal = com.force.legacy_fnode(:, :, ilc_gp) ...
    + com.faddnode(:, :, ilc_gp);
end
legacy_foundation = zeros(nnode, 1);
is_support = false(nnode, 1);
is_support(com.support.idnode) = true;
legacy_foundation(is_support) = -legacy_nodal(is_support, 3);
legacy_floor(~is_support) = legacy_floor(~is_support) ...
  - legacy_nodal(~is_support, 3);

% すべての重量源を同じ節点再配分規則へ通す
[legacy_floor, legacy_foundation, girder_self, wall_self, ...
  column_self, pool, cantilever_pool] = redistribute_kbrace_mid(com, ...
  legacy_floor, legacy_foundation, sw.fg(:, 3), sw.fw(:, 3), ...
  sw.fc(:, 3), raw.pool, raw.cantilever_pool);

nclass = size(pool, 3);
ntype = size(pool, 4);
long_usage = [PRM.WUSAGE_COMMON, PRM.WUSAGE_FRAME];
seismic_usage = [PRM.WUSAGE_COMMON, PRM.WUSAGE_SEISMIC];
long_pool = reshape(sum(pool(:, long_usage, :, :), 2), nnode, ...
  nclass, ntype);
seismic_pool = reshape(sum(pool(:, seismic_usage, :, :), 2), nnode, ...
  nclass, ntype);
long_cantilever = reshape(sum(cantilever_pool(:, long_usage, :, :), ...
  2), nnode, nclass, ntype);
seismic_cantilever = reshape(sum(cantilever_pool(:, ...
  seismic_usage, :, :), 2), nnode, nclass, ntype);

weight.long = build_long_weight(com, long_pool, long_cantilever, ...
  pool, legacy_floor, legacy_foundation, girder_self, wall_self, ...
  column_self);
weight.seismic = build_seismic_weight(com, seismic_pool, ...
  seismic_cantilever, legacy_floor, legacy_foundation, girder_self, ...
  wall_self, column_self);
weight.story = build_story_weight(com, weight.seismic);

return
end


function long = build_long_weight(com, detail, cantilever, pool, ...
  legacy_floor, legacy_foundation, girder_self, wall_self, column_self)
%build_long_weight - 長期節点重量と固定・積載帳票用物理量を作る
%
%   long = build_long_weight(com, detail, cantilever, pool,
%   legacy_floor, legacy_foundation, girder_self, wall_self,
%   column_self) は、共通・ラーメン用重量を長期重量へ構成し、
%   D.L・L.Lの欄対応と累計を計算する。
%
%   入力引数:
%     com               - 節点・グリッド情報
%     detail            - 長期用の区分×タイプ別重量 [nnode×3×7]
%     cantilever        - 片持梁由来の長期分類重量 [nnode×3×7]
%     pool              - 用途別の全重量プール [nnode×3×3×7]
%     legacy_floor      - 旧入力の床重量 [nnode×1]
%     legacy_foundation - 旧入力の基礎重量 [nnode×1]
%     girder_self       - 自動計算した梁自重 [nnode×1]
%     wall_self         - 自動計算した壁自重 [nnode×1]
%     column_self       - 自動計算した柱自重 [nnode×1]
%
%   出力引数:
%     long - 長期の分類値、合計および累計
nnode = com.nnode;
display_class = [PRM.WCLASS_LL, PRM.WCLASS_DL];
ll_floor = detail(:, PRM.WCLASS_LL, PRM.WTYPE_FLOOR);
dl_floor = detail(:, PRM.WCLASS_DL, PRM.WTYPE_FLOOR);
ll_special = detail(:, PRM.WCLASS_LL, PRM.WTYPE_SPECIAL);
dl_special = detail(:, PRM.WCLASS_DL, PRM.WTYPE_SPECIAL);
girder_input = reshape(sum(cantilever(:, display_class, ...
  PRM.WTYPE_GIRDER), 2), nnode, 1);
wall_input = reshape(sum(detail(:, display_class, PRM.WTYPE_WALL), ...
  2), nnode, 1);
frame_out = reshape(sum(detail(:, display_class, PRM.WTYPE_FRAME_OUT), ...
  2), nnode, 1);
foundation = legacy_foundation + reshape(sum(detail(:, display_class, ...
  PRM.WTYPE_FOUNDATION), 2), nnode, 1);
frame_correction = pool(:, PRM.WUSAGE_FRAME, PRM.WCLASS_DIRECT, ...
  PRM.WTYPE_CORRECTION);
correction = reshape(frame_correction, nnode, 1);
input_total = reshape(sum(detail, [2, 3]), nnode, 1);
ll_input = reshape(sum(detail(:, PRM.WCLASS_LL, :), [2, 3]), nnode, 1);
ll_total = legacy_floor + ll_input;
total = legacy_floor + legacy_foundation + girder_self + wall_self ...
  + column_self + input_total;
dl_total = total - ll_total;

long.upper_floor = legacy_floor + ll_floor;
long.upper_special = ll_special;
long.lower_floor = dl_floor;
long.girder = girder_self + girder_input;
long.wall = wall_self + wall_input;
long.lower_special = dl_special;
long.column = column_self;
long.correction = correction;
long.frame_out = frame_out;
long.foundation = foundation;
long.floor = legacy_floor + ll_floor + dl_floor;
long.special = ll_special + dl_special;
long.total = total;

% 同一グリッドの累計は3系列を一度の走査で求める
cumulative = calc_grid_cumulative(com, [ll_total, dl_total, total]);
long.upper_axial = cumulative(:, 1);
long.axial = cumulative(:, 2);
long.axial_tl = cumulative(:, 3);

return
end


function seismic = build_seismic_weight(com, detail, cantilever, ...
  legacy_floor, legacy_foundation, girder_self, wall_self, column_self)
%build_seismic_weight - 地震用の節点別分類値と累計を作る
%
%   seismic = build_seismic_weight(com, detail, cantilever, legacy_floor,
%   legacy_foundation, girder_self, wall_self, column_self) は、共通・
%   地震用重量と既存重量を合成し、地震時節点重量表と地震用重量表が
%   参照する物理量を計算する。
%
%   入力引数:
%     com                 - 節点・グリッド情報
%     detail              - 地震用の区分×タイプ別重量 [nnode×3×7]
%     cantilever          - 片持梁由来の地震用分類重量 [nnode×3×7]
%     legacy_floor        - 旧入力の床重量 [nnode×1]
%     legacy_foundation   - 旧入力の基礎重量 [nnode×1]
%     girder_self         - 自動計算した梁自重 [nnode×1]
%     wall_self           - 自動計算した壁自重 [nnode×1]
%     column_self         - 自動計算した柱自重 [nnode×1]
%
%   出力引数:
%     seismic - 地震用の分類値、合計および累計
nnode = com.nnode;
display_class = [PRM.WCLASS_LL, PRM.WCLASS_DL];
cantilever_girder = reshape(sum(cantilever(:, display_class, ...
  PRM.WTYPE_GIRDER), 2), nnode, 1);
floor_dl = reshape(detail(:, PRM.WCLASS_DL, PRM.WTYPE_FLOOR), nnode, 1);
floor_ll = reshape(detail(:, PRM.WCLASS_LL, PRM.WTYPE_FLOOR), nnode, 1);
wall_weight = reshape(sum(detail(:, display_class, PRM.WTYPE_WALL), ...
  2), nnode, 1);
special_weight = reshape(sum(detail(:, :, PRM.WTYPE_SPECIAL), 2), ...
  nnode, 1);
correction_weight = reshape(sum(detail(:, :, PRM.WTYPE_CORRECTION), ...
  2), nnode, 1);
frame_out_weight = reshape(sum(detail(:, display_class, ...
  PRM.WTYPE_FRAME_OUT), 2), nnode, 1);
foundation_weight = reshape(sum(detail(:, display_class, ...
  PRM.WTYPE_FOUNDATION), 2), nnode, 1);
input_total = reshape(sum(detail, [2, 3]), nnode, 1);
total = legacy_floor + legacy_foundation + girder_self + wall_self ...
  + column_self + input_total;

seismic.column = column_self;
seismic.girder = girder_self;
seismic.cantilever_girder = cantilever_girder;
seismic.floor_dl = legacy_floor + floor_dl;
seismic.floor_ll = floor_ll;
seismic.floor = legacy_floor + floor_dl + floor_ll;
seismic.wall = wall_self + wall_weight;
seismic.special = special_weight;
seismic.correction = correction_weight;
seismic.frame_out = frame_out_weight;
seismic.foundation = legacy_foundation + foundation_weight;
seismic.total = total;
seismic.axial = calc_grid_cumulative(com, total);

return
end


function story = build_story_weight(com, seismic)
%build_story_weight - 地震用の節点別重量を層別へ集計する
%
%   story = build_story_weight(com, seismic) は、地震用の節点別物理量
%   を層別に合計し、地震用重量帳票の分類値とwiを作る。分類の合成は
%   build_seismic_weight で確定済みで、ここでは層集計だけを行う。
%
%   入力引数:
%     com     - 節点・層情報
%     seismic - 地震用の節点別物理量
%
%   出力引数:
%     story - 層別のD.L・L.L分類値、自重およびwi
values = [seismic.floor_dl, seismic.floor_ll, ...
  seismic.girder + seismic.cantilever_girder, seismic.column, ...
  seismic.wall, seismic.foundation, seismic.frame_out, ...
  seismic.special, seismic.correction, seismic.total];
totals = calc_story_total(com, values);
story.floor_dl = totals(:, 1);
story.floor_ll = totals(:, 2);
story.girder = totals(:, 3);
story.column = totals(:, 4);
story.wall = totals(:, 5);
story.foundation = totals(:, 6);
story.frame_out = totals(:, 7);
story.special = totals(:, 8);
story.correction = totals(:, 9);
story.total = totals(:, 10);

return
end


function cumulative = calc_grid_cumulative(com, values)
%calc_grid_cumulative - 同一グリッドの節点重量を上階から累計する
%
%   cumulative = calc_grid_cumulative(com, values) は、表示対象の通常
%   節点について、同一X・Yグリッドの値を上階から現在層まで累計する。
%   複数系列を列に並べて渡すと、一度の走査で全系列を累計する。
%
%   入力引数:
%     com    - 節点・グリッド・層情報
%     values - 節点別の物理量 [nnode×k]
%
%   出力引数:
%     cumulative - 各表示節点での上階からの累計 [nnode×k]
nseries = size(values, 2);
cumulative = zeros(com.nnode, nseries);
for iy = 1:com.nbly
  for ix = 1:com.nblx
    running = zeros(1, nseries);
    for offset = 1:com.nstory
      istory = com.nstory - offset + 1;
      idnode = find_idnode_from_grid(com, ix, iy, istory);
      if isempty(idnode)
        continue
      end
      running = running + sum(values(idnode, :), 1);
      cumulative(idnode, :) = repmat(running, length(idnode), 1);
    end
  end
end

return
end


function totals = calc_story_total(com, values)
%calc_story_total - 帳票対象節点の物理量を層別に合計する
%
%   totals = calc_story_total(com, values) は、同一化済み節点とブレース
%   用柱分割節点を除いた値を層別に合計する。複数系列を列に並べて
%   渡すと、一度の走査で全系列を合計する。
%
%   入力引数:
%     com    - 節点・層情報
%     values - 節点別の物理量 [nnode×k]
%
%   出力引数:
%     totals - 層別合計 [nstory×k]
totals = zeros(com.nstory, size(values, 2));
is_report = com.node.idrep == 0 ...
  & com.node.type ~= PRM.NODE_BRACE_FOR_COLUMN;
for istory = 1:com.nstory
  target = is_report & com.node.idstory == istory;
  totals(istory, :) = sum(values(target, :), 1);
end

return
end
