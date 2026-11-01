function joint = countup_nominal_column_joint(member_column, idmec, idsub)
%countup_nominal_column_joint - 名目柱の端部接合条件を組み立てる
%
%   joint = countup_nominal_column_joint(member_column, idmec, ...
%     idsub) は、名目柱を構成する解析用柱要素から、分割前の
%   柱脚条件と柱頭条件を取得する。構成要素は柱脚から柱頭の順で、
%   最下部と最上部の物理外端を参照する。
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
base_columns = [1, 3];
top_columns = [2, 4];

% 名目柱の最下部要素の柱脚条件と最上部要素の柱頭条件を採る。
ic_base = idmec(:, 1);
ic_top = idmec(sub2ind(size(idmec), (1:nnmc)', idsub(:, 2)));
joint = zeros(nnmc, 4);
joint(:, base_columns) = member_column.joint(ic_base, base_columns);
joint(:, top_columns) = member_column.joint(ic_top, top_columns);

return
end
