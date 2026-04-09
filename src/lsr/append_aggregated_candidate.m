function xlist = append_aggregated_candidate(xlist, xvar0, vtype, ...
  do_aggregated_restore)
%append_aggregated_candidate - cgsr 集約候補で xlist を置換する
%
%   xlist = append_aggregated_candidate(xlist, xvar0, vtype, ...
%     do_aggregated_restore) は、cgsr 違反ごとの個別候補行列 xlist
%   に対し、フェーズ1a の集約候補（柱 max、梁 min）で**置換**する。
%   置換条件は以下を全て満たす場合に限る:
%     1. do_aggregated_restore が true
%     2. xlist の行数（ncg）が 2 以上
%     3. 集約結果が xvar0 と異なる（空振り回避）
%
%   置換を行うことで後段 unique/select_minpf の負荷を削減する。
%   個別候補は集約の材料として使われるのみで、出力には含めない。
%   集約ロジック自体は aggregate_cgsr_candidates を呼び出す。
%
%   入力引数:
%     xlist                 - 個別候補の行列 [ncg x nvar]
%     xvar0                 - 集約の基点となる現解 [1 x nvar]
%     vtype                 - 各変数の種別コード [nvar x 1] or [1 x nvar]
%     do_aggregated_restore - 集約置換の有効フラグ（logical）
%
%   出力引数:
%     xlist - ON かつ条件充足時は集約候補 1 行、それ以外は入力のまま

if ~do_aggregated_restore
  return
end
ncg = size(xlist, 1);
if ncg < 2
  return
end
xvar_agg = aggregate_cgsr_candidates(xlist, xvar0, vtype);
xlist = select_aggregated_or_individual(xlist, xvar0, xvar_agg);

return
end
