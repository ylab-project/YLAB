function candidate_ids = find_section_symbol_candidates( ...
  section_table, symbol)
%find_section_symbol_candidates - 配置符号に一致する断面候補を抽出する
%
%   candidate_ids = find_section_symbol_candidates(section_table, ...
%     symbol) は、subindexが空でないfull_name（添字付き符号）を
%   先に照合し、一致しない場合はname（記号）が一致する全行を返す。
%
%   入力引数:
%     section_table - name、subindex、full_nameを持つYLAB内部の断面表
%     symbol        - 配置で入力された符号
%
%   出力引数:
%     candidate_ids - 符号の解釈後に残る断面行番号。一致なしは空配列
%
%   備考:
%     - full_nameとnameはYLAB内部名である。

is_full_name_match = ~cellfun(@isempty, section_table.subindex) & ...
  strcmp(section_table.full_name, symbol);
candidate_ids = find(is_full_name_match);
if isempty(candidate_ids)
  candidate_ids = find(strcmp(section_table.name, symbol));
end

return
end
