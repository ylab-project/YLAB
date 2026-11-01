function [nodal_force, issues] = set_legacy_nodal_force_block(blocks, com)
%set_legacy_nodal_force_block - 従来節点荷重の値と配置指定を正規化する
%
%   [nodal_force, issues] = set_legacy_nodal_force_block(blocks, com)
%   は、従来形式の節点荷重を出現順に読み込む。荷重ケースの空欄には
%   直前の有効なケースを適用し、未知ケースと混在形式の行を除く。
%
%   入力引数:
%     blocks - 従来形式と判定された節点荷重ブロックの構造体配列
%     com    - 荷重ケースを持つ共通データ
%
%   出力引数:
%     nodal_force - 配置指定・ケース・6成分・入力位置のテーブル
%     issues      - 入力値の検証で収集した警告

n = sum(arrayfun(@(block) size(block.data, 1), blocks));
selector = cell(n, 3);
ilc = zeros(n, 1);
f = zeros(n, 6);
irow = zeros(n, 1);
nforce = 0;
issues = empty_input_issues();
for ib = 1:length(blocks)
  data = blocks(ib).data;
  previous_case = '';
  for ir = 1:size(data, 1)
    csv_line = blocks(ib).origrows(ir);
    input_case = tochar(data{ir, 1});
    case_name = input_case;
    if isempty(case_name)
      case_name = previous_case;
    end
    if any(strcmp(input_case, {'DL', 'LL'})) || isempty(case_name)
      input_value = input_case;
      if isempty(input_value)
        input_value = '空欄';
      end
      issues = add_input_issue(issues, 'NodalForceMixedFormat', '', ...
        '節点荷重', ib, csv_line, input_value, 1, 0, 1, '');
      continue
    end
    lc = find(strcmp(com.loadcase.name, case_name), 1);
    if isempty(lc)
      issues = add_input_issue(issues, 'ElementLoadUnknownLoadCase', ...
        '', '節点荷重', ib, csv_line, case_name, 1, 0, 1, '');
      continue
    end
    previous_case = case_name;
    nforce = nforce + 1;
    selector(nforce, :) = cellfun(@tochar, data(ir, 2:4), ...
      'UniformOutput', false);
    ilc(nforce) = lc;
    f(nforce, :) = cell2mat(data(ir, 5:10));
    irow(nforce) = ir;
  end
end
nodal_force = table(selector, ilc, f, irow);
nodal_force = nodal_force(1:nforce, :);

return
end
