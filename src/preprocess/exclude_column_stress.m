function column_rank = exclude_column_stress(com)
%exclude_column_stress - 断面算定省略（F指定）柱の検定除外処理
%
%   column_rank = exclude_column_stress(com) は、入力の
%   「断面算定の省略（柱符号毎）」でFが指定された柱断面グループの
%   ランクをFDにして幅厚比検定を除外する。断面算定の省略は検定の
%   除外のみを意味し、設計変数は固定しない。
%
%   入力引数:
%     com - 共通データ構造体
%
%   出力引数:
%     column_rank - 柱断面グループのランク [nsc×1]
%
%   備考:
%     - RC柱（RCRS断面）は set_exclusion_column_stress_block で
%       自動的に検定対象外となる。梁側にこの自動除外はない。
%     - 関連関数: set_exclusion_column_stress_block

% 検定除外断面の処理（幅厚比の除外 -> ランクFD）
column_rank = com.section.column.rank;
is_column_stress = com.exclusion.is_section_column_allowable_stress;
column_rank(~is_column_stress) = PRM.COLUMN_RANK_FD;

return
end
