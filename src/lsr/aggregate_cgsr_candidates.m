function xvar_agg = aggregate_cgsr_candidates(xlist, xvar0, vtype)
%aggregate_cgsr_candidates - cgsr 個別候補を単純 max/min で集約
%
%   xvar_agg = aggregate_cgsr_candidates(xlist, xvar0, vtype) は、
%   cgsr 違反ごとに生成された候補行列 xlist を1行に集約する。
%   個別候補の和集合を取って安全側評価とする目的で、柱変数
%   （HSS_D, HSS_T）は断面拡大方向（max）、梁変数（WFS_H, WFS_B,
%   WFS_TW, WFS_TF）は縮小方向（min）で統合する。vtype はホワイト
%   リスト判定で、列挙外の変数は xvar0 の値を維持する。
%
%   入力引数:
%     xlist  - cgsr 違反ごとの候補行列 [ncg x nvar]
%     xvar0  - 集約の基点となる現解 [1 x nvar]
%     vtype  - 各変数の種別コード [nvar x 1] または [1 x nvar]
%
%   出力引数:
%     xvar_agg - 集約後の候補 [1 x nvar]

is_up = (vtype == PRM.HSS_D | vtype == PRM.HSS_T);
is_dn = (vtype == PRM.WFS_H | vtype == PRM.WFS_B ...
  | vtype == PRM.WFS_TW | vtype == PRM.WFS_TF);
xvar_agg = xvar0;
xvar_agg(is_up) = max(xlist(:, is_up), [], 1);
xvar_agg(is_dn) = min(xlist(:, is_dn), [], 1);

return
end
