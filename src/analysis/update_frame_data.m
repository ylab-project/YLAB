function com = update_frame_data(secdim, com, options)
%update_frame_data - 評価断面の座標と柱の解析用分割を確定する
%
%   com = update_frame_data(secdim, com, options) は、構造階高を更新し、
%   選択した天端が柱内にある場合だけブレースの接続節点を設ける。
%   分割要否が変わった場合に限り部材番号と依存する対応を再構成する。
%
%   入力引数:
%     secdim  - 評価する断面寸法 [nsec×7] (mm)
%     com     - 入力柱と現在の解析用部材を持つ共通データ
%     options - 解析オプション
%
%   出力引数:
%     com - 座標、分割部材、自由度および荷重対応を更新した共通データ

idg1 = com.member.girder.idnode1;
idg2 = com.member.girder.idnode2;
dz0 = com.node.z(idg2) - com.node.z(idg1);
[zcoord, nodez, mglevel, com.story, com.floor] = update_geometry_z( ...
  secdim, com.baseline, com.node, com.story, com.floor, ...
  com.section, com.member, options);
com.baseline.z.coord = zcoord;
com.node.z = nodez;
com.member.girder.level = mglevel;
% 梁の両端が同じだけ上下する通常ケースでは補剛長は不変。
if any(dz0 ~= nodez(idg2) - nodez(idg1))
  idm2n = [com.member.property.idnode1 com.member.property.idnode2];
  lm = calc_member_length_from_node(com.node, idm2n);
  com.member.girder = countup_girder_stiffening(com, lm);
  [com.member.girder, com.nominal.girder] = ...
    countup_girder_stiffening_direct(com, lm);
end

% 対象がないモデルでは分割の照合も対応の生成も行わない。
mb = com.member.brace;
idb = find(mb.idz(:, 1) == 1 & (mb.type == PRM.BRACE_MEMBER_TYPE_X ...
  | mb.type == PRM.BRACE_MEMBER_TYPE_K_UPPER));
if isempty(idb)
  return
end

mc = com.member.column;
ci = com.member.column_input;
nmc = numel(ci.idnode1);
idc = zeros(numel(idb), 1);
z = nan(nmc, 1);
for i = 1:numel(idb)
  ib = idb(i);
  [ztop, ic] = calc_brace_foundation_z(ib, com.member, com.node, options);
  if isnan(ztop)
    continue
  end
  idc(i) = ic;
  if options.position_brace_foundation_girder ~= ...
      PRM.BRACE_FOUNDATION_GIRDER_TOP
    continue
  end
  in1 = ci.idnode1(ic);
  in2 = ci.idnode2(ic);
  a = ztop - com.node.z(in1);
  L = com.node.z(in2) - com.node.z(in1);
  if 0 < a && a < L
    % 区間配分を検証した鉛直S柱に限定する。
    if com.node.x(in1) ~= com.node.x(in2) || com.node.y(in1) ~= ...
        com.node.y(in2) || mc.angle(ic) ~= 0 || ...
        com.member.property.section_type(mc.idme(ic)) == PRM.RCRS
      throw_err('Geometry', 'BraceColumnSplitUnsupported', ...
        ic, mc.floor_name{ic}, mc.coord_name{ic, 1}, mc.coord_name{ic, 2});
    end
    z(ic) = ztop;
  end
end
ids = find(~isnan(z));
if ~isequal(ids, find(mc.type(1:nmc) == PRM.COLUMN_FOR_BRACE_BODY))
  % 変更対象の直接荷重は連続行と区間の対応を保てないため停止する。
  changed = xor(~isnan(z), mc.type(1:nmc) == PRM.COLUMN_FOR_BRACE_BODY);
  if isfield(com, 'force')
    ef = com.force.element;
    for ic = find(changed)'
      idme = mc.idme(ic);
      if mc.idsplit(ic) > 0
        idme = mc.idme([ic; mc.idsplit(ic)]);
      end
      rows = find(ismember(ef.idme, idme));
      if ~isempty(rows)
        throw_err('Geometry', 'ColumnElementLoadSplitChange', ic, ...
          mc.floor_name{ic}, mc.coord_name{ic,1}, mc.coord_name{ic,2}, ...
          mat2str(ef.csv_row(rows)'));
      end
    end
  end
  com = rebuild_column_split(com, ids, idb, idc, z);
else
  % 節点番号と自由度は維持し、取り付き高さだけを反映する。
  com.node.z(mc.idnode1(ids)) = z(ids);
end

return
end

function com = rebuild_column_split(com, ids, idb, idc, z)
%rebuild_column_split - 入力柱から分割部材と依存する対応を生成する
%
%   com = rebuild_column_split(com, ids, idb, idc, z)
%   は、分割対象が変わったときにだけ呼び出す。
%
%   入力引数:
%     com     - 更新前の共通データ
%     ids     - 分割する入力柱番号
%     idb     - 天端指定の対象ブレース番号
%     idc     - 対象ブレースの入力柱番号（0は接続柱なし）
%     z       - 入力柱ごとの取り付き高さ (mm)
%
%   出力引数:
%     com - 分割を反映した共通データ

ci = com.member.column_input;
mc = com.member.column;
mc = struct2table(mc);
node = struct2table(com.node);
mp = com.member.property;
nmc = numel(ci.idnode1);
nsplit = numel(ids);

% 基本節点は入力時の番号を保ち、追加節点だけを置き換える。
idz = unique(node.idz(node.type == PRM.NODE_BRACE_FOR_COLUMN));
com.baseline.z(idz, :) = [];
node = node(node.type ~= PRM.NODE_BRACE_FOR_COLUMN, :);
if nsplit > 0
  blz = com.baseline.z(1, :);
  nz = height(com.baseline.z) + 1;
  blz.idstory = nz;
  blz.isdummy = true;
  blz.name = strcat(blz.name, '-BRACE-JOINT');
  com.baseline.z = [com.baseline.z; blz];
end
com.nblz = height(com.baseline.z);
nnode = height(node);
% 入力柱の端点・結合条件・分割番号を未分割の読込時状態へ戻し、
% 断面変更後の取り付き高さで分割を作り直す。
mc = mc(1:nmc, :);
mc.idnode1 = ci.idnode1;
mc.idnode2 = ci.idnode2;
mc.idz = ci.idz;
mc.isthrough = ci.isthrough;
mc.idconnected = ci.idconnected;
mc.joint = ci.joint;
mc.type(:) = PRM.COLUMN_STANDARD;
mc.idsplit = zeros(nmc, 1);

addnode = node(ci.idnode1(ids), :);
addnode.type(:) = PRM.NODE_BRACE_FOR_COLUMN;
addnode.idrep(:) = 0;
addnode.z = z(ids);
if nsplit > 0
  addnode.idz(:) = nz;
  addnode.zname(:) = blz.name;
end
% 標準高さは元の柱脚を基準とし、積算長さの定義を保つ。
node = [node; addnode];
addcol = mc(ids, :);
addcol.type(:) = PRM.COLUMN_FOR_BRACE_FOUNDATION;
addcol.idnode2 = nnode + (1:nsplit)';
addcol.idsplit = ids;
addcol.idconnected = ids;
addcol.isthrough(:) = false;
addcol.joint(:) = PRM.FIX;
mc.idnode1(ids) = addcol.idnode2;
mc.type(ids) = PRM.COLUMN_FOR_BRACE_BODY;
mc.idsplit(ids) = nmc + (1:nsplit)';
if nsplit > 0
  mc.idz(ids, 1) = nz;
  addcol.idz(:, 2) = nz;
end
% 通し柱の上側接続は、新たな下側区間へつなぎ替える。
for i = 1:nsplit
  mc.idconnected(mc.idconnected == ids(i)) = nmc + i;
end
mc = [mc; addcol];

% 梁・入力柱の番号は保ち、追加柱と後続部材の全体番号を再配列する。
idold = [com.member.girder.idme; com.member.column.idme(1:nmc); ...
  com.member.column.idme(ids); com.member.brace.idme; ...
  com.member.horizontal_brace.idme];
idnew = zeros(com.nme, 1);
idnew(com.member.girder.idme) = (1:com.nmeg)';
idnew(com.member.column.idme(1:nmc)) = com.nmeg + (1:nmc)';
for ic = 1:nmc
  if com.member.column.idsplit(ic) > 0 && mc.idsplit(ic) > 0
    idnew(com.member.column.idme(com.member.column.idsplit(ic))) = ...
      com.nmeg + mc.idsplit(ic);
  end
end
com.nmec = height(mc);
mc.idme = com.nmeg + (1:com.nmec)';
com.member.brace.idme = com.nmeg + com.nmec + (1:com.nmeb)';
com.member.horizontal_brace.idme = com.nmeg + com.nmec + com.nmeb ...
  + (1:com.nmehb)';
idnew(com.member.property.type == PRM.BRACE) = com.member.brace.idme;
idnew(com.member.property.type == PRM.HORIZONTAL_BRACE) = ...
  com.member.horizontal_brace.idme;

% ブレース下端は、分割しない場合も入力柱の元の柱脚へ戻す。
for i = 1:numel(idb)
  if idc(i) > 0
    com.member.brace.idnode1(idb(i)) = mc.idnode1(idc(i));
  end
end
mp = mp(idold, :);
mp.idmec(mc.idme) = (1:com.nmec)';
mp.idnode1(mc.idme) = mc.idnode1;
mp.idnode2(mc.idme) = mc.idnode2;
mp.idnode1(com.member.brace.idme) = com.member.brace.idnode1;
% 柱脚断面は支持された元の柱脚を持つ要素へ割り当てる。
idseccb = com.member.property.idseccb(com.member.column.idme(1:nmc));
for ic = 1:nmc
  if com.member.column.idsplit(ic) > 0
    idseccb(ic) = com.member.property.idseccb( ...
      com.member.column.idme(com.member.column.idsplit(ic)));
  end
end
mp.idseccb(mc.idme) = 0;
idbase = (1:nmc)';
idbase(ids) = mc.idsplit(ids);
mp.idseccb(mc.idme(idbase)) = idseccb;
mc.idmehss(:) = 0;
is_hss = mp.section_type(mc.idme) == PRM.HSS;
mc.idmehss(is_hss) = (1:nnz(is_hss))';
com.member.column = table2struct(mc, 'ToScalar', true);
com.member.property = mp;
com.node = table2struct(node, 'ToScalar', true);
com.nnode = height(node);
com.nme = height(mp);
com.column_buckling_K.Kx = com.column_buckling_K.Kx([(1:nmc)'; ids]);
com.column_buckling_K.Ky = com.column_buckling_K.Ky([(1:nmc)'; ids]);

com = update_frame_topology(com);

% 荷重の作用先は物理節点・部材の対応から更新する。
if isfield(com, 'force')
  com.force.legacy_element.idme = idnew(com.force.legacy_element.idme);
  com.force.element.idme = idnew(com.force.element.idme);
  names = {'fnode', 'faddnode', 'faddnode_report_excl'};
  for i = 1:numel(names)
    value = com.(names{i});
    value = value(1:nnode, :, :);
    value(nnode + (1:nsplit), :, :) = 0;
    com.(names{i}) = value;
  end
  value = com.force.legacy_fnode(1:nnode, :, :);
  value(nnode + (1:nsplit), :, :) = 0;
  com.force.legacy_fnode = value;
  [ar, M0] = calc_element_force_ar(com.force.legacy_element, ...
    com.nme, com.nlc);
  [ar1, M01] = calc_element_force_ar(com.force.element, com.nme, com.nlc);
  com.ar = ar + ar1;
  com.M0 = M0 + M01;
end

return
end
