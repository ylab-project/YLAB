function fnode = set_legacy_nodal_force_block(blocks, com)
%set_legacy_nodal_force_block - 従来形式の節点荷重ブロックを読む
%
%   fnode = set_legacy_nodal_force_block(blocks, com) は、従来形式と
%   判定された節点荷重ブロックを出現順に読み、荷重ケース別の節点
%   荷重ベクトルを返す。2行目以降の荷重ケース空欄は直前の有効な
%   荷重ケースを継承する。他形式の行と未知荷重ケースは警告して
%   未反映とし、後続行の読込を継続する。
%
%   入力引数:
%     blocks - 従来形式と判定された節点荷重ブロックの構造体配列
%     com    - 節点、基準線および荷重ケースを持つ共通オブジェクト
%
%   出力引数:
%     fnode - 荷重ケース別の節点荷重 [nnode×6×nlc]
fnode = zeros(com.nnode, 6, com.nlc);
issues = empty_input_issues();
for iblock = 1:length(blocks)
  block = blocks(iblock);
  data = block.data;
  previous_case = '';
  for irow = 1:size(data, 1)
    csv_row = block.origrows(irow);
    input_case = tochar(data{irow, 1});
    if isempty(input_case)
      case_name = previous_case;
    else
      case_name = input_case;
    end

    if any(strcmp(input_case, {'DL', 'LL'})) || isempty(case_name)
      input_value = input_case;
      if isempty(input_value)
        input_value = '空欄';
      end
      issues = add_input_issue(issues, 'NodalForceMixedFormat', '', ...
        '節点荷重', iblock, csv_row, input_value, 1, 0, 1, '');
      continue
    end

    ilc = find(strcmp(com.loadcase.name, case_name), 1);
    if isempty(ilc)
      issues = add_input_issue(issues, 'ElementLoadUnknownLoadCase', ...
        '', '節点荷重', iblock, csv_row, case_name, 1, 0, 1, '');
      continue
    end
    previous_case = case_name;

    idnode = find_idnode_from_names(tochar(data{irow, 2}), ...
      tochar(data{irow, 3}), tochar(data{irow, 4}), com);
    if idnode == 0
      throw_err('Input', 'NodeNotFound', irow);
    end
    force = cell2mat(data(irow, 5:10));
    fnode(idnode, :, ilc) = fnode(idnode, :, ilc) + reshape(force, 1, 6);
  end
end
report_input_issues(issues);

return
end