function issues = check_foundation_support(idnodes, com, block_name, ...
  iblock, csv_row, input_value, issues)
%check_foundation_support - 基礎重量の対象が支点に接するか確認する
%
%   issues = check_foundation_support(idnodes, com, block_name, iblock,
%   csv_row, input_value, issues) は、`タイプ=基礎重量`の行が支点節点
%   に接するかを確認する。接しない場合も入力どおり計上し、警告だけを
%   記録する（内部設計5章）。
%
%   入力引数:
%     idnodes     - 判定対象の節点番号（線材は両端節点）
%     com         - 共通オブジェクト
%     block_name  - 入力ブロック名
%     iblock      - 同名ブロックの出現番号
%     csv_row     - 元CSV行番号
%     input_value - 警告に残す入力値
%     issues      - 警告レコード
%
%   出力引数:
%     issues - 警告を追加した警告レコード
if any(ismember(idnodes(:), com.support.idnode))
  return
end
issues = add_input_issue(issues, 'ElementLoadFoundationOffSupport', ...
  '', block_name, iblock, csv_row, input_value, 1, 1, 0, '');

return
end
