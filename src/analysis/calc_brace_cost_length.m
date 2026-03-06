function lm_brace_cost = calc_brace_cost_length(...
  member_brace, member_girder, member_column, ...
  node, ~, floor, ...
  stype_sec, idsecc2sec, idsecg2sec, secdim)
%calc_brace_cost_length - ブレース積算用部材長を算出
%
%   lm_brace_cost = calc_brace_cost_length(
%     member_brace, member_girder, member_column,
%     node, story, floor,
%     stype_sec, idsecc2sec, idsecg2sec, secdim) は、
%   SS7積算マニュアル(4.4.5)に基づき、ブレースの
%   積算用部材長を算出する。標準階高ベースの内法
%   対角長を返す。
%
%   入力引数:
%     member_brace  - ブレース部材テーブル
%     member_girder - 梁部材テーブル
%     member_column - 柱部材テーブル
%     node          - 節点テーブル
%     story         - 層テーブル
%     floor         - フロアテーブル
%     stype_sec     - 断面種別 [nsec×1]
%     idsecc2sec    - 柱断面→統一断面ID
%     idsecg2sec    - 梁断面→統一断面ID
%     secdim        - 断面寸法 [nsec×ncol]
%
%   出力引数:
%     lm_brace_cost - 積算用部材長 [nmeb×1]

nmeb = length(member_brace.idme);
nfl = size(floor, 1);
nmec = length(member_column.idme);

% ブレース節点
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

% 接続する柱・梁の部材番号（両端）
brc_idmec1 = member_brace.idmec1;
brc_idmec2 = member_brace.idmec2;
brc_idmeg1 = member_brace.idmeg1;
brc_idmeg2 = member_brace.idmeg2;

% 梁レベル調整（下げが負）
glv = member_girder.level;

% 梁せいの取得（S梁のみ: 鉄骨積算はS梁で決まる）
Hs = zeros(size(secdim, 1), 1);
Hs(stype_sec == PRM.WFS) = ...
  secdim(stype_sec == PRM.WFS, 1);

% 柱幅の取得（断面種別ごと）
Dc = zeros(size(secdim, 1), 1);
Dc(stype_sec == PRM.HSS) = ...
  secdim(stype_sec == PRM.HSS, 1);
Dc(stype_sec == PRM.RCRS) = ...
  secdim(stype_sec == PRM.RCRS, 3);

% 梁せい（梁部材ID→統一断面ID→せい）
idmg2s = idsecg2sec(member_girder.idsecg);
Hg = Hs(idmg2s);

% 柱幅（柱部材ID→統一断面ID→幅）
idmc2s = idsecc2sec(member_column.idsecc);
Dc_col = Dc(idmc2s);

% 分割節点の有効idz（BRACE_BODY柱のidfloorで補正）
idz_eff = node.idz;
idz_eff = build_effective_idz(...
  idz_eff, node, member_column, nmec);

lm_brace_cost = zeros(nmeb, 1);

for ib = 1:nmeb
  in1 = idnode1(ib);
  in2 = idnode2(ib);

  % 分割節点判定（glvスキップ用）
  is_split1 = ...
    node.type(in1) == PRM.NODE_BRACE_FOR_COLUMN ...
    || node.type(in1) ...
    == PRM.NODE_BRACE_FOR_GIRDER;
  is_split2 = ...
    node.type(in2) == PRM.NODE_BRACE_FOR_COLUMN ...
    || node.type(in2) ...
    == PRM.NODE_BRACE_FOR_GIRDER;

  % --- 鉛直距離（標準階高ベース） ---
  idz1 = idz_eff(in1);
  idz2 = idz_eff(in2);
  idz_lo = min(idz1, idz2);
  idz_hi = max(idz1, idz2);
  if idz_hi > idz_lo && idz_hi - 1 <= nfl
    Lz = sum(floor.standard_height( ...
      idz_lo:idz_hi - 1));
  else
    Lz = 0;
  end

  % glv補正（分割節点はスキップ）
  idg1 = brc_idmeg1(ib, :);
  idg1 = idg1(idg1 > 0);
  if is_split1 || isempty(idg1)
    max_glv1 = 0;
  else
    max_glv1 = max(glv(idg1));
  end

  idg2 = brc_idmeg2(ib, :);
  idg2 = idg2(idg2 > 0);
  if is_split2 || isempty(idg2)
    max_glv2 = 0;
  else
    max_glv2 = max(glv(idg2));
  end

  % dz + glv の符号補正
  delta = -node.dz(in1) + node.dz(in2) ...
    + max_glv2 - max_glv1;
  if idz2 >= idz1
    Lz = Lz + delta;
  else
    Lz = Lz - delta;
  end
  Lz = abs(Lz);

  % --- 梁面減算（鉛直方向、S梁のみ） ---
  % SS7仕様: 常に両端のS梁面を減算する。
  % 分割節点側にS梁がない場合は他端のS梁せいを
  % 使用する。
  beam_H1 = max_beam_depth(idg1, Hg);
  beam_H2 = max_beam_depth(idg2, Hg);
  if beam_H1 == 0 && beam_H2 > 0
    beam_H1 = beam_H2;
  elseif beam_H2 == 0 && beam_H1 > 0
    beam_H2 = beam_H1;
  end
  Lz_inner = ...
    Lz - beam_H1 / 2 - beam_H2 / 2;

  % --- 水平距離 ---
  dx = node.x(in2) - node.x(in1);
  dy = node.y(in2) - node.y(in1);
  Lx = sqrt(dx^2 + dy^2);

  % --- 柱面減算（ブレース範囲内の柱のみ） ---
  idc1 = brc_idmec1(ib, :);
  idc1 = idc1(idc1 > 0);
  max_col_D1 = max_col_depth_in_range(...
    idc1, Dc_col, member_column, ...
    idz_lo, idz_hi);

  idc2 = brc_idmec2(ib, :);
  idc2 = idc2(idc2 > 0);
  max_col_D2 = max_col_depth_in_range(...
    idc2, Dc_col, member_column, ...
    idz_lo, idz_hi);

  Lx_inner = ...
    Lx - max_col_D1 / 2 - max_col_D2 / 2;

  % --- 積算長さ ---
  lm_brace_cost(ib) = ...
    sqrt(Lz_inner^2 + Lx_inner^2);
end

return
end

function idz_eff = build_effective_idz(...
  idz_eff, node, member_column, nmec)
%build_effective_idz - 分割節点の有効idzを補正
%
%   idz_eff = build_effective_idz(idz_eff,
%     node, member_column, nmec) は、
%   NODE_BRACE_FOR_COLUMNの節点に対して
%   接続するBRACE_BODY柱のidfloorを有効idzとして
%   設定する。
%
%   入力引数:
%     idz_eff       - 節点idz配列（コピー）
%     node          - 節点テーブル
%     member_column - 柱部材テーブル
%     nmec          - 柱部材数
%
%   出力引数:
%     idz_eff - 補正後の有効idz配列

nnode = length(node.type);
for in = 1:nnode
  if node.type(in) ~= PRM.NODE_BRACE_FOR_COLUMN
    continue
  end
  for ic = 1:nmec
    if member_column.type(ic) ...
        ~= PRM.COLUMN_FOR_BRACE_BODY
      continue
    end
    if member_column.idnode1(ic) == in ...
        || member_column.idnode2(ic) == in
      idz_eff(in) = ...
        member_column.idfloor(ic);
      break
    end
  end
end

return
end

function H = max_beam_depth(idg, Hg)
%max_beam_depth - 梁群の最大S梁せいを返す
%
%   H = max_beam_depth(idg, Hg) は、
%   梁IDリスト中のS梁せいの最大値を返す。
%   S梁がない場合は0を返す。
%
%   入力引数:
%     idg - 梁部材IDリスト
%     Hg  - 梁せい配列（WFSのみ非0）
%
%   出力引数:
%     H - 最大S梁せい

if isempty(idg)
  H = 0;
else
  H = max(Hg(idg));
end

return
end

function D = max_col_depth_in_range(...
  idc, Dc_col, member_column, idz_lo, idz_hi)
%max_col_depth_in_range - ブレース範囲内の柱幅最大値
%
%   D = max_col_depth_in_range(idc, Dc_col,
%     member_column, idz_lo, idz_hi) は、
%   柱IDリスト中でブレースのフロア範囲
%   (idz_lo〜idz_hi) 内にある柱の最大幅を返す。
%
%   入力引数:
%     idc           - 柱部材IDリスト
%     Dc_col        - 柱幅配列
%     member_column - 柱部材テーブル
%     idz_lo        - ブレース下端フロアID
%     idz_hi        - ブレース上端フロアID
%
%   出力引数:
%     D - 最大柱幅

D = 0;
for ic = idc
  idf = member_column.idfloor(ic);
  if idf >= idz_lo && idf <= idz_hi
    D = max(D, Dc_col(ic));
  end
end

return
end
