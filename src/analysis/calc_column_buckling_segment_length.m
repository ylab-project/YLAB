function lmc_bk = calc_column_buckling_segment_length(...
  member_column, member_girder, nominal_column, ...
  stype_sec, idsecg2sec, secdim, lmc)
%calc_column_buckling_segment_length - 柱座屈用部材長を算出
%
%   lmc_bk = calc_column_buckling_segment_length(
%     member_column, member_girder,
%     nominal_column, stype_sec, idsecg2sec,
%     secdim, lmc) は、
%   柱の構造心間距離（lmc）からRC梁接続端のD/2を
%   控除した座屈用部材長を算出する。斜め柱では D/2 を
%   柱軸方向に投影して控除する（SS7仕様、4.1.2柱(1)部材長）。
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
%
%   出力引数:
%     lmc_bk - 柱セグメント座屈用部材長 [nmec×1]

lmc_bk = lmc;

% 梁せいの取得（RC梁: secdim列2）
Hg = zeros(size(secdim, 1), 1);
Hg(stype_sec == PRM.RCRS) = secdim(stype_sec == PRM.RCRS, 2);
idmg2s = idsecg2sec(member_girder.idsecg);
Hg_gir = Hg(idmg2s);
stype_gir = stype_sec(idmg2s);

% 梁部材の節点番号
gn1 = member_girder.idnode1;
gn2 = member_girder.idnode2;

% 柱の節点番号と通り心ベース投影係数
cn1 = member_column.idnode1;
cn2 = member_column.idnode2;
proj = column_axial_projection(member_column.cz_std);

% 名目柱ごとにRC梁せい控除（D/2 を柱軸方向に投影）
nnmc = size(nominal_column.idmec, 1);
for inc = 1:nnmc
  nsub = nominal_column.idsub(inc, 2);
  imcs = nominal_column.idmec(inc, 1:nsub);

  % 下端
  ic_bot = imcs(1);
  d_bot = find_rc_beam_depth(cn1(ic_bot), gn1, gn2, ...
    stype_gir, Hg_gir);
  if d_bot > 0
    lmc_bk(ic_bot) = lmc_bk(ic_bot) - (d_bot / 2) * proj(ic_bot);
  end

  % 上端
  ic_top = imcs(nsub);
  d_top = find_rc_beam_depth(cn2(ic_top), gn1, gn2, ...
    stype_gir, Hg_gir);
  if d_top > 0
    lmc_bk(ic_top) = lmc_bk(ic_top) - (d_top / 2) * proj(ic_top);
  end
end

return
end

%--------------------------------------------------------------
function D = find_rc_beam_depth(nd, gn1, gn2, ...
  stype_gir, Hg_gir)
%find_rc_beam_depth - 節点に接続するRC梁せいを取得
%
%   D = find_rc_beam_depth(nd, gn1, gn2,
%     stype_gir, Hg_gir) は、
%   指定節点に接続するRC梁のうち最大のせいDを返す。
%   RC梁がなければ0を返す。
%
%   入力引数:
%     nd        - 対象節点番号
%     gn1       - 梁始端節点番号 [nmg×1]
%     gn2       - 梁終端節点番号 [nmg×1]
%     stype_gir - 梁断面種別 [nmg×1]
%     Hg_gir    - 梁せい [nmg×1]
%
%   出力引数:
%     D - RC梁せい（なければ0）

idx = find((gn1 == nd | gn2 == nd) ...
  & stype_gir == PRM.RCRS);
if isempty(idx)
  D = 0;
else
  D = max(Hg_gir(idx));
end

return
end
