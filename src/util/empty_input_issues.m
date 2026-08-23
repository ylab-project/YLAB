function issues = empty_input_issues()
%empty_input_issues - 入力警告の空構造体配列を返す
%
%   issues = empty_input_issues() は、入力警告の識別、入力位置、入力値、
%   反映件数およびフォールバック先を列に持つ空構造体配列を返す。
%
%   出力引数:
%     issues - 空の警告レコード構造体配列
issues = struct('id', {}, 'detail', {}, 'block_name', {}, ...
  'iblock', {}, 'row', {}, 'input_value', {}, 'input_count', {}, ...
  'applied_count', {}, 'unapplied_count', {}, 'fallback', {});

return
end