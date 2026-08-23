function [head, ilc, issues] = read_weight_head(names, ilc_gp, ...
  block_name, iblock, csv_row, issues)
%read_weight_head - 行頭3列を重量区分へ解釈し解析ケースを決める
%
%   [head, ilc, issues] = read_weight_head(names, ilc_gp, block_name,
%   iblock, csv_row, issues) は、重量ブロックの行頭3列（DL/LL・
%   ラーメン用/地震用・タイプ）を read_weight_category で内部IDへ
%   解釈し、未知の区分、未知のタイプおよびLLの通常外分類を警告へ
%   記録する。共通・ラーメン用の行は長期解析ケース、`地震用`の行は
%   解析非計上（0）とする（内部設計5章）。
%
%   入力引数:
%     names      - 行頭3列の値 {DL/LL, 用途, タイプ}（char）
%     ilc_gp     - 長期解析ケース番号
%     block_name - 入力ブロック名
%     iblock     - 同名ブロックの出現番号
%     csv_row    - 元CSV行番号
%     issues     - 警告レコード
%
%   出力引数:
%     head   - 区分の解釈結果。is_validが偽の行は反映しない
%     ilc    - 解析荷重ケース番号。地震用と未解釈は0
%     issues - 警告を追加した警告レコード
ilc = 0;
head = read_weight_category(names{1}, names{2}, names{3});
if ~head.is_valid
  detail = sprintf('%s/%s', names{1}, names{2});
  issues = add_input_issue(issues, 'ElementLoadUnknownCategory', ...
    detail, block_name, iblock, csv_row, detail, 1, 0, 1, '');
  return
end
if head.unknown_type
  issues = add_input_issue(issues, 'ElementLoadUnknownType', ...
    names{3}, block_name, iblock, csv_row, names{3}, 1, 1, 0, ...
    PRM.WTYPE_NAMES{PRM.WTYPE_FLOOR});
end
if head.is_unusual
  input_value = sprintf('%s/%s', names{1}, names{3});
  issues = add_input_issue(issues, 'ElementLoadLlUnusualType', '', ...
    block_name, iblock, csv_row, input_value, 1, 1, 0, '');
end
if head.wusage ~= PRM.WUSAGE_SEISMIC
  ilc = ilc_gp;
end

return
end
