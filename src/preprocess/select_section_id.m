function idsection = select_section_id(section_table, symbol, ...
  idstory, idznominal)
%select_section_id - 柱配置または大梁配置の符号から断面を選択する
%
%   idsection = select_section_id(section_table, symbol, idstory, ...
%     idznominal) は、section_tableのfull_name（符号）または
%   name（記号）がsymbolに一致する行から、
%   次の規則で断面行を一意に選択する。
%
%   選択規則:
%     1. full_nameの一致を、nameだけの一致より優先する。
%     2. idznominalが同じ候補は距離0とする。
%     3. idznominalが異なる候補はidstoryの差を距離とする。
%     4. 一致順位と距離が同じ場合はidstoryの小さい候補を優先する。
%     5. 候補なしは未定義、1から4で同順位の行が複数なら曖昧とする。
%
%   入力引数:
%     section_table - YLAB内部の断面表
%     symbol        - 柱配置または大梁配置の「符号」
%     idstory       - 配置部材の階または層に対応する内部ID
%     idznominal    - 対応する通常階または通常層の内部ID
%
%   出力引数:
%     idsection - 選択した断面行番号

is_full_name = strcmp(section_table.full_name, symbol);
is_base_name = strcmp(section_table.name, symbol);
candidate_ids = find(is_full_name | is_base_name);
if isempty(candidate_ids)
  error('YLAB:Input:SectionNotFound', ...
    '断面%sが見つかりません（層番号: %g）', symbol, idstory);
end

% 符号の一致順位、距離、idstoryをこの順に比較する。
match_rank = ~is_full_name(candidate_ids);
candidate_stories = section_table.idstory(candidate_ids);
story_distance = abs(candidate_stories - idstory);
is_same_nominal = section_table.idznominal(candidate_ids) == idznominal;
story_distance(is_same_nominal) = 0;
is_selected = match_rank == min(match_rank);
is_selected = is_selected & ...
  story_distance == min(story_distance(is_selected));
is_selected = is_selected & ...
  candidate_stories == min(candidate_stories(is_selected));

if nnz(is_selected) ~= 1
  error('YLAB:Input:AmbiguousSection', ...
    '断面%sの参照先を一意に特定できません（層番号: %g）', ...
    symbol, idstory);
end
idsection = candidate_ids(is_selected);

return
end
