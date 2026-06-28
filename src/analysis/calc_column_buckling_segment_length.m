function lmc_bk = calc_column_buckling_segment_length(...
  member_column, member_girder, nominal_column, ...
  stype_sec, idsecg2sec, secdim, lmc, is_girder_target, ...
  rigid_zone_direct)
%calc_column_buckling_segment_length - 柱座屈用部材長を算出
%
%   lmc_bk = calc_column_buckling_segment_length(
%     member_column, member_girder,
%     nominal_column, stype_sec, idsecg2sec,
%     secdim, lmc, is_girder_target, rigid_zone_direct) は、
%   柱の構造心間距離（lmc）からコンクリート重複相当控除長さを
%   除いた座屈用部材長を算出する。RC梁面控除は斜め柱で柱軸方向に
%   投影し、直接入力柱剛域がある端部では直接入力値を優先する。
%
%   控除は名目柱の最下端・最上端のみに適用し、
%   中間のブレース分割節点では控除しない。
%
%   入力引数:
%     member_column  - 柱部材テーブル（cz_std を含む）
%     member_girder  - 梁部材テーブル
%     nominal_column - 名目柱部材情報
%     stype_sec      - 断面種別配列 [nsec×1]
%     idsecg2sec     - 梁断面→統一断面変換配列
%     secdim         - 断面寸法配列 [nsec×ncol]
%     lmc            - 柱セグメント構造心間距離 [nmec×1]
%     is_girder_target - 控除対象に含める梁 [nmg×1]（省略時は全梁）
%     rigid_zone_direct - 直接入力柱剛域 [nmec×2]（列1:柱脚, 列2:柱頭）
%
%   出力引数:
%     lmc_bk - 柱セグメント座屈用部材長 [nmec×1]

lmc_bk = lmc;
if nargin < 8 || isempty(is_girder_target)
  is_girder_target = true(size(member_girder.idme));
end
is_girder_target = is_girder_target(:);
if nargin < 9 || isempty(rigid_zone_direct)
  rigid_zone_direct = nan(length(lmc), 2);
end

% 梁せいの取得（RC梁: secdim列2）
Hg = zeros(size(secdim, 1), 1);
Hg(stype_sec == PRM.RCRS) = secdim(stype_sec == PRM.RCRS, 2);
idmg2s = idsecg2sec(member_girder.idsecg);
Hg_gir = Hg(idmg2s);

% 梁部材の節点番号
girder_node = [member_girder.idnode1, member_girder.idnode2];

% 柱の節点番号と通り心ベース投影係数
cn1 = member_column.idnode1;
cn2 = member_column.idnode2;
proj = column_axial_projection(member_column.cz_std);

% 名目柱ごとに端部控除を適用
nnmc = size(nominal_column.idmec, 1);
for inc = 1:nnmc
  nsub = nominal_column.idsub(inc, 2);
  imcs = nominal_column.idmec(inc, 1:nsub);

  % 下端
  ic_bot = imcs(1);
  d_bot = calc_connected_girder_depth( ...
    cn1(ic_bot), girder_node, Hg_gir, is_girder_target);
  rc_overlap_bot = (d_bot / 2) * proj(ic_bot);
  overlap_bot = select_column_buckling_end_overlap( ...
    rc_overlap_bot, rigid_zone_direct(ic_bot, 1));
  if overlap_bot > 0
    lmc_bk(ic_bot) = lmc_bk(ic_bot) - overlap_bot;
  end

  % 上端
  ic_top = imcs(nsub);
  d_top = calc_connected_girder_depth( ...
    cn2(ic_top), girder_node, Hg_gir, is_girder_target);
  rc_overlap_top = (d_top / 2) * proj(ic_top);
  overlap_top = select_column_buckling_end_overlap( ...
    rc_overlap_top, rigid_zone_direct(ic_top, 2));
  if overlap_top > 0
    lmc_bk(ic_top) = lmc_bk(ic_top) - overlap_top;
  end
end

return
end

function overlap = select_column_buckling_end_overlap(...
  rc_overlap, rigid_zone_direct)
%select_column_buckling_end_overlap - 柱端部控除長さを選択する

if isnan(rigid_zone_direct)
  overlap = rc_overlap;
else
  overlap = rigid_zone_direct;
end

return
end
