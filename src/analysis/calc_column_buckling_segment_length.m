function lmc_bk = calc_column_buckling_segment_length( ...
  nominal_column, lmc, column_rigid_zone)
%calc_column_buckling_segment_length - 柱座屈用部材長を算出
%
%   lmc_bk = calc_column_buckling_segment_length(
%     nominal_column, lmc, column_rigid_zone) は、柱の構造心間距離
%   （lmc）から、柱剛性表と同じ柱剛域長さを端部控除した
%   座屈用部材長を算出する。
%
%   column_rigid_zone は列1を柱脚側、列2を柱頭側とする。
%   値は剛域計算側で柱軸方向へ投影済みであり、本関数では
%   再投影しない。NaN は控除なしの 0 として扱う。
%
%   控除は名目柱の最下端・最上端のみに適用し、
%   中間のブレース分割節点では控除しない。
%
%   入力引数:
%     nominal_column    - 名目柱部材情報
%     lmc               - 柱セグメント構造心間距離 [nmec×1]
%     column_rigid_zone - 柱剛域長さ [nmec×2]
%
%   出力引数:
%     lmc_bk - 柱セグメント座屈用部材長 [nmec×1]

lmc_bk = lmc;
if nargin < 3 || isempty(column_rigid_zone)
  column_rigid_zone = zeros(length(lmc), 2);
end
column_rigid_zone(isnan(column_rigid_zone)) = 0;

% 名目柱ごとに端部控除を適用
nnmc = size(nominal_column.idmec, 1);
for inc = 1:nnmc
  nsub = nominal_column.idsub(inc, 2);
  imcs = nominal_column.idmec(inc, 1:nsub);

  % 下端
  ic_bot = imcs(1);
  overlap_bot = column_rigid_zone(ic_bot, 1);
  if overlap_bot > 0
    lmc_bk(ic_bot) = lmc_bk(ic_bot) - overlap_bot;
  end

  % 上端
  ic_top = imcs(nsub);
  overlap_top = column_rigid_zone(ic_top, 2);
  if overlap_top > 0
    lmc_bk(ic_top) = lmc_bk(ic_top) - overlap_top;
  end
end

return
end
