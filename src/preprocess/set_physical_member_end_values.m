function values = set_physical_member_end_values(values, ids, ...
  member_type, end_values, artificial_end_types)
%set_physical_member_end_values - 物理外端だけへ入力値を設定
%
%   values = set_physical_member_end_values(values, ids, ...
%     member_type, end_values, artificial_end_types) は、候補部材の
%   物理外端だけへ端部入力値を設定する。人工分割端を持つ部材種別は
%   対応する端の設定対象から除外する。
%
%   入力引数:
%     values               - 設定前の端部値 [nm x 2]
%     ids                  - 入力の適用候補となる部材番号
%     member_type          - 部材種別 [nm x 1]
%     end_values           - 始端・終端の入力値 [1 x 2]
%     artificial_end_types - 人工始端・終端を持つ部材種別 [1 x 2]
%                            空配列の場合は全候補へ設定する
%
%   出力引数:
%     values - 物理外端へ入力値を設定した端部値 [nm x 2]

for iend = 1:2
  value = end_values(iend);
  if isnan(value)
    continue
  end

  ids_end = ids;
  if ~isempty(artificial_end_types)
    is_artificial = member_type(ids_end) == artificial_end_types(iend);
    ids_end(is_artificial) = [];
  end
  values(ids_end,iend) = value;
end

return
end
