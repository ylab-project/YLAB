function issues = add_input_issue(issues, id, detail, block_name, ...
  iblock, csv_row, input_value, input_count, applied_count, ...
  unapplied_count, fallback)
%add_input_issue - 入力警告レコードを集約用配列へ追加する
%
%   issues = add_input_issue(issues, id, detail, block_name, iblock,
%   csv_row, input_value, input_count, applied_count, unapplied_count,
%   fallback) は、警告種別、入力位置、入力値、反映件数および
%   フォールバック先を警告レコードへ追加する。通知は
%   report_input_issuesが読込完了時に行う。
%
%   入力引数:
%     issues          - 警告レコード構造体配列
%     id              - error_messages_tableの警告ID
%     detail          - 異常理由などの詳細文字列
%     block_name      - 入力ブロック名
%     iblock          - 同名ブロックの出現番号
%     csv_row         - 元CSV行番号
%     input_value     - 警告対象の入力値
%     input_count     - 入力件数
%     applied_count   - 適用件数
%     unapplied_count - 未反映件数
%     fallback        - フォールバック先。ない場合は空文字
%
%   出力引数:
%     issues - 警告レコードを追加した構造体配列
issue.id = id;
issue.detail = detail;
issue.block_name = block_name;
issue.iblock = iblock;
issue.row = csv_row;
issue.input_value = input_value;
issue.input_count = input_count;
issue.applied_count = applied_count;
issue.unapplied_count = unapplied_count;
issue.fallback = fallback;
issues(end + 1, 1) = issue;

return
end