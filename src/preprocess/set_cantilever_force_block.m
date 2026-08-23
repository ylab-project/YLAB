function nodal_force = set_cantilever_force_block(dbc, com)
%set_cantilever_force_block - 片持梁の荷重を取付節点へ縮約して読む
%
%   nodal_force = set_cantilever_force_block(dbc, com) は、`片持梁
%   配置`の幾何レコードを解決し、`要素荷重(片持梁)`のC・Qoを対応
%   する配置の方向・長さ・先端移動から取付節点（元端節点）の6成分へ
%   縮約した節点荷重テーブルを返す入力アダプターである。片持梁を
%   YLAB要素へ新設せず、縮約結果だけを一度反映する。解析・重量への
%   加算は行わない。対応する配置がない行、重複する配置キーを参照
%   する行、参照できない取付節点、規定外の方向、方向の基準となる柱
%   の回転を取得できない行、および幾何を解決できない長さの行は反映
%   せず警告する（内部設計3章・5章）。
%
%   入力引数:
%     dbc - data_block_classオブジェクト
%     com - 共通オブジェクト
%
%   出力引数:
%     nodal_force - idnode・ilc・6成分・重量分類・入力位置を列に持つ
%                   節点荷重テーブル
issues = empty_input_issues();
ilc_gp = find_ilc_long_term(com.loadcase);

[placements, issues] = read_placements(dbc, com, issues);
placement_keys = {placements.key};
blocks = dbc.get_data_blocks('要素荷重(片持梁)');
nforce_max = 0;
for ib = 1:length(blocks)
  nforce_max = nforce_max + size(blocks(ib).data, 1);
end

% 各列を入力行数の上限まで確保し、配置の解決後に切り詰める
idnode = zeros(nforce_max, 1);
ilc = zeros(nforce_max, 1);
f = zeros(nforce_max, 6);
wclass = zeros(nforce_max, 1);
wusage = zeros(nforce_max, 1);
wtype = zeros(nforce_max, 1);
is_cantilever = false(nforce_max, 1);
block_name = cell(nforce_max, 1);
iblock = zeros(nforce_max, 1);
irow = zeros(nforce_max, 1);
csv_row = zeros(nforce_max, 1);
nforce = 0;

for ib = 1:length(blocks)
  block = blocks(ib);
  apply_block();
end
report_input_issues(issues);

nodal_force = table(idnode, ilc, f, wclass, wusage, wtype, ...
  is_cantilever, block_name, iblock, irow, csv_row);
nodal_force = nodal_force(1:nforce, :);

return

  function apply_block()
    %apply_block - 要素荷重(片持梁)の各行を縮約してテーブル行化する
    %
    %   親の block・ib・placements を読み、列配列・nforce・issues を
    %   親ワークスペースで直接更新するネスト関数である。
    data = block.data;
    label = '要素荷重(片持梁)';
    for ir = 1:size(data, 1)
      csv_line = block.origrows(ir);
      names = cellfun(@tochar, data(ir, 1:3), 'UniformOutput', false);
      [head, ilc_line, issues] = read_weight_head(names, ilc_gp, ...
        label, ib, csv_line, issues);
      if ~head.is_valid
        continue
      end

      % 対象片持梁（層・X軸・Y軸・方向・片持梁符号）
      target = cellfun(@tochar, data(ir, 4:8), 'UniformOutput', false);
      input_value = strjoin(target, '/');
      if any(cellfun(@is_all_token, target(1:3)))
        issues = add_input_issue(issues, 'ElementLoadAllNotSupported', ...
          '', label, ib, csv_line, input_value, 1, 0, 1, '');
        continue
      end
      ip = find(strcmp(placement_keys, strjoin(target, '|')), 1);
      if isempty(ip)
        issues = add_input_issue(issues, 'CantileverLoadUnresolved', ...
          '配置なし', label, ib, csv_line, input_value, 1, 0, 1, '');
        continue
      end
      placement = placements(ip);
      if ~isempty(placement.reason)
        issues = add_input_issue(issues, 'CantileverLoadUnresolved', ...
          placement.reason, label, ib, csv_line, input_value, ...
          1, 0, 1, '');
        continue
      end

      % C・Qoを取付節点の6成分へ縮約する（空欄は数値0）
      c_base = normalize_missing_zero(data{ir, 9});
      c_tip = normalize_missing_zero(data{ir, 10});
      q_base = normalize_missing_zero(data{ir, 11});
      q_tip = normalize_missing_zero(data{ir, 12});
      f6 = calc_cantilever_nodal_force(placement.r, c_base, c_tip, ...
        q_base, q_tip);

      nforce = nforce + 1;
      idnode(nforce) = placement.idnode;
      ilc(nforce) = ilc_line;
      f(nforce, :) = f6;
      wclass(nforce) = head.wclass;
      wusage(nforce) = head.wusage;
      wtype(nforce) = head.wtype;
      is_cantilever(nforce) = true;
      block_name{nforce} = label;
      iblock(nforce) = ib;
      irow(nforce) = ir;
      csv_row(nforce) = csv_line;
      if head.wtype == PRM.WTYPE_FOUNDATION
        issues = check_foundation_support(placement.idnode, com, ...
          label, ib, csv_line, input_value, issues);
      end
    end

    return
  end
end


function [placements, issues] = read_placements(dbc, com, issues)
%read_placements - 片持梁配置を幾何レコードへ解決する
placements = struct('key', {}, 'idnode', {}, 'r', {}, ...
  'reason', {}, 'iblock', {}, 'csv_row', {});
blocks = dbc.get_data_blocks('片持梁配置');
for iblock = 1:length(blocks)
  data = blocks(iblock).data;
  for irow = 1:size(data, 1)
    placement = resolve_placement(data(irow, :), com);
    placement.iblock = iblock;
    placement.csv_row = blocks(iblock).origrows(irow);
    placements(end + 1, 1) = placement; %#ok<AGROW>
  end
end

% 同一キーの重複は幾何を一意に解決できないため配置を警告し、
% そのキーを参照する荷重行を未反映にする
keys = {placements.key};
for k = 1:length(placements)
  if nnz(strcmp(keys, placements(k).key)) > 1
    placements(k).reason = '配置キー重複';
    issues = add_input_issue(issues, 'CantileverPlacementDuplicated', ...
      '', '片持梁配置', placements(k).iblock, placements(k).csv_row, ...
      placements(k).key, 1, 0, 1, '');
  end
end

return
end


function placement = resolve_placement(row, com)
%resolve_placement - 片持梁配置1行の幾何を一意に解決する
%
%   基準柱は元端節点を柱頭とする柱（直下階の柱）を優先し、なければ
%   元端節点を柱脚とする柱を用いる。基準方向はX+/X-/Y+/Y-を基準柱の
%   強軸角度だけ全体Z軸まわりに回転した水平単位ベクトルとする
%   （内部設計3章）。
names = cellfun(@tochar, row(1:5), 'UniformOutput', false);
placement.key = strjoin(names, '|');
placement.idnode = 0;
placement.r = zeros(1, 3);
placement.reason = '';

% 取付節点（元端節点）
idnode = find_idnode_from_names(names{1}, names{2}, names{3}, com);
if idnode == 0
  placement.reason = '取付節点なし';
  return
end
placement.idnode = idnode;

% 基準方向
switch names{4}
  case 'X+'
    base_dir = [1, 0, 0];
  case 'X-'
    base_dir = [-1, 0, 0];
  case 'Y+'
    base_dir = [0, 1, 0];
  case 'Y-'
    base_dir = [0, -1, 0];
  otherwise
    placement.reason = '規定外の方向';
    return
end

% 基準柱（元端節点を柱頭とする直下の柱を優先する）
member_column = com.member.column;
ic = find(member_column.idnode2 == idnode, 1);
if isempty(ic)
  ic = find(member_column.idnode1 == idnode, 1);
end
if isempty(ic)
  placement.reason = '基準柱なし';
  return
end
angle = deg2rad(member_column.angle(ic));
rot = [cos(angle), -sin(angle), 0; sin(angle), cos(angle), 0; 0, 0, 1];
e1 = (rot * base_dir.').';
e2 = cross([0, 0, 1], e1);

% 元端－先端ベクトル（長さは通り心基点の跳ね出し長さ）
len = row{6};
tip_lr = normalize_missing_zero(row{7});
tip_ud = normalize_missing_zero(row{8});
if ~(len > 0)
  placement.reason = '長さ0以下';
  return
end
placement.r = len * e1 + tip_lr * e2 + tip_ud * [0, 0, 1];

return
end
