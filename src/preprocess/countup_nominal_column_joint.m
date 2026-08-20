function joint = countup_nominal_column_joint(member_column, idmec, idsub)
%countup_nominal_column_joint - 名目柱の端部接合条件を組み立てる
%
%   joint = countup_nominal_column_joint(member_column, idmec, ...
%     idsub) は、名目柱を構成する解析用柱要素から、分割前の
%   柱脚条件と柱頭条件を取得する。下側オフセット区間は
%   柱脚条件の取得対象から除外する。
%
%   入力引数:
%     member_column - 柱部材テーブル
%     idmec         - 名目柱の構成要素番号 [nnmc×maxseg]
%     idsub         - 名目柱の構成要素範囲 [nnmc×2]
%
%   出力引数:
%     joint - 名目柱の接合条件 [nnmc×4]
%             列順はX柱脚、X柱頭、Y柱脚、Y柱頭

nnmc = size(idmec, 1);
joint = zeros(nnmc, 4);
base_columns = [1, 3];
top_columns = [2, 4];

for inc = 1:nnmc
  nsub = idsub(inc, 2);
  ids = idmec(inc, 1:nsub);

  % 柱脚条件は名目柱本体の最下部要素から取得する
  is_foundation = member_column.type(ids) ...
    == PRM.COLUMN_FOR_BRACE_FOUNDATION;
  ids_body = ids(~is_foundation);
  ic_base = ids_body(1);
  ic_top = ids(end);

  joint(inc, base_columns) = member_column.joint(ic_base, base_columns);
  joint(inc, top_columns) = member_column.joint(ic_top, top_columns);
end

return
end
