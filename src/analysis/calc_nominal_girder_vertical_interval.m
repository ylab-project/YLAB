function lb_vertical = calc_nominal_girder_vertical_interval( ...
  lmg, idmeg, braced, xc_design)
%calc_nominal_girder_vertical_interval - 名目梁4位置の鉛直補剛区間
%
%   lb_vertical = calc_nominal_girder_vertical_interval(lmg, idmeg,
%     braced, xc_design) は、前処理で確定した鉛直補剛点トポロジーと
%   形状更新後のセグメント長から補剛点の軸座標を作り、共通区間生成
%   関数で4検定位置（左端、右端、中央L、中央R）の鉛直補剛区間を
%   求める。
%
%   中央L・中央Rは同じ断面算定位置に対する左右の候補である。中央位置
%   が補剛点と一致する場合だけ両者が異なる区間となり、一致しない場合
%   は同じ区間を返す。
%
%   入力引数:
%     lmg       - 梁セグメント芯間距離 [nmg×1]
%     idmeg     - 名目梁→セグメント対応表 [nnmg×maxsub]
%     braced    - 内部境界が鉛直補剛点か
%                 [nnmg×(maxsub-1) logical]
%     xc_design - 断面算定の中央位置（内法スパン中央）[nnmg×1]
%
%   出力引数:
%     lb_vertical - 4検定位置の鉛直補剛区間長 [nnmg×4]
%                   列順: 左端, 右端, 中央L, 中央R

nnmg = size(idmeg, 1);
lb_vertical = zeros(nnmg, 4);

for inmg = 1:nnmg
  igs = idmeg(inmg, :);
  igs(igs==0) = [];
  seg_length = lmg(igs);
  seg_length = seg_length(:);

  % 補剛点の軸座標（名目梁始端からの累加位置）
  boundary = cumsum(seg_length(1:end-1));
  is_braced = braced(inmg, 1:numel(boundary));

  bracing = calc_nominal_bracing_intervals(sum(seg_length), ...
    boundary(is_braced(:)), [], false, xc_design(inmg));
  spans = bracing.intervals;
  center = bracing.check_interval;
  lb_vertical(inmg, :) = [spans(1) spans(end) center.left center.right];
end

return
end
