function idsection = select_section_id(section_table, symbol, ...
  idstory, idznominal)
%select_section_id - 配置符号に対応する最近傍の断面を選択する
%
%   idsection = select_section_id(section_table, symbol, idstory, ...
%     idznominal) は、配置符号を解釈して断面候補を抽出し、
%   階・層に対する最近傍と同距離時の下側優先で1行を選択する。
%
%   選択規則:
%     1. 添字付きfull_nameに一致する候補を用い、一致しなければ
%        nameに一致する候補を用いる。
%     2. idznominalが同じ候補は距離0とする。
%     3. idznominalが異なる候補はidstoryの差を距離とする。
%     4. 距離が同じ場合はidstoryの小さい候補を優先する。
%     5. 候補なしは未定義、1から4で同順位の複数行は曖昧とする。
%
%   入力引数:
%     section_table - YLAB内部の断面表
%     symbol        - 配置で入力された符号
%     idstory       - 配置部材の階または層に対応する内部ID
%     idznominal    - 対応する通常階または通常層の内部ID
%
%   出力引数:
%     idsection - 選択した断面行番号

candidate_ids = find_section_symbol_candidates(section_table, symbol);
if isempty(candidate_ids)
  error('YLAB:Input:SectionNotFound', ...
    '断面%sが見つかりません（層番号: %g）', symbol, idstory);
end

candidate_stories = section_table.idstory(candidate_ids);
story_distance = abs(candidate_stories - idstory);
is_same_nominal = section_table.idznominal(candidate_ids) == idznominal;
story_distance(is_same_nominal) = 0;
is_selected = story_distance == min(story_distance);
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
