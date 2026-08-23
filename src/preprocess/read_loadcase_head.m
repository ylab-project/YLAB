function [ilc, issues] = read_loadcase_head(case_name, com, ...
  block_name, iblock, csv_row, issues)
%read_loadcase_head - 行頭の荷重ケース名を解析ケース番号へ解釈する
%
%   [ilc, issues] = read_loadcase_head(case_name, com, block_name,
%   iblock, csv_row, issues) は、応力計算用特殊荷重の行頭にある荷重
%   ケース名を解析荷重ケース番号へ解決する。空欄または未知の名前は
%   0を返して警告へ記録し、呼び出し側は行を反映しない（内部設計5章）。
%
%   入力引数:
%     case_name  - 荷重ケース名（char）
%     com        - 共通オブジェクト
%     block_name - 入力ブロック名
%     iblock     - 同名ブロックの出現番号
%     csv_row    - 元CSV行番号
%     issues     - 警告レコード
%
%   出力引数:
%     ilc    - 解析荷重ケース番号。解決できない場合は0
%     issues - 警告を追加した警告レコード
ilc = 0;
if ~isempty(case_name)
  ilc_found = find(strcmp(com.loadcase.name, case_name), 1);
  if ~isempty(ilc_found)
    ilc = ilc_found;
  end
end
if ilc == 0
  issues = add_input_issue(issues, 'ElementLoadUnknownLoadCase', '', ...
    block_name, iblock, csv_row, case_name, 1, 0, 1, '');
end

return
end
