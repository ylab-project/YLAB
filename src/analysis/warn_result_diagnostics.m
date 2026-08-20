function warn_result_diagnostics(com, result)
%warn_result_diagnostics - resultへ保持した解析診断を警告する
%
%   warn_result_diagnostics(com, result) は、解析中には発行せず
%   resultへ保持した診断情報を、出力境界でまとめて警告する。
%   候補評価のresultは出力境界を通らないため、LSR候補評価中の
%   発行はなく、1回の実行につき一度だけ発行される。
%
%   入力引数:
%     com    - 共通データ構造体
%     result - 解析結果構造体
%              (ignored_moment、rigid_zone_overflowを参照)
%
%   出力引数:
%     なし

warn_ignored_rotational_moments(result.ignored_moment, com.node, ...
  com.member.property.idnode1, com.member.property.idnode2, ...
  com.loadcase.name);
warn_column_base_rigid_zone_overflow(result.rigid_zone_overflow);

return
end
