function check_loadcase_names(names)
%check_loadcase_names - 荷重ケース名の予約語を検査する
%
%   check_loadcase_names(names) は、`荷重ケース`ブロックの荷重ケース
%   名に予約語 DL・LL がないかを検査し、見つかった場合はエラーとして
%   読込を停止する。DL・LL は`節点荷重`ブロックの新旧形式判定
%   （最初のデータ行の第1列）と衝突するため使用できない
%   （内部設計4章、2026-08-22決定）。
%
%   入力引数:
%     names - 荷重ケース名のcell配列 [n×1]
for i = 1:length(names)
  if any(strcmp(names{i}, {'DL', 'LL'}))
    throw_err('Input', 'LoadCaseReservedName', names{i}, i);
  end
end

return
end
