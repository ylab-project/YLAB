function girder_rank = exclude_girder_stress(com)
%exclude_girder_stress - 断面算定省略（F指定）梁の検定除外処理
%
%   girder_rank = exclude_girder_stress(com) は、入力の
%   「断面算定の省略（梁符号毎）」でFが指定された梁断面グループの
%   ランクをFDにして幅厚比検定を除外する。断面算定の省略は検定の
%   除外のみを意味し、設計変数は固定しない。
%
%   入力引数:
%     com - 共通データ構造体
%
%   出力引数:
%     girder_rank - 梁断面グループのランク [nsg×1]
%
%   備考:
%     - 断面を固定する場合は、入力の設計変数ブロックでF宣言する
%       （検定除外からの固定連動は行わない）。
%     - 関連関数: set_exclusion_girder_stress_block

% 検定除外断面の処理（幅厚比の除外 -> ランクFD）
girder_rank = com.section.girder.rank;
is_girder_stress = com.exclusion.is_section_girder_allowable_stress;
girder_rank(~is_girder_stress) = PRM.GIRDER_RANK_FD;

return
end
