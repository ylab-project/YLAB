function idmec = find_idcolumn_from_idxyz(idx, idy, idz, member_column)
%find_idcolumn_from_idxyz - 座標範囲から柱部材番号を検索
%
%   idmec = find_idcolumn_from_idxyz(...
%     idx, idy, idz, member_column) は、指定されたX、Y、Z座標範囲に
%   合致する柱部材番号を返す。柱が人工節点で分割されている場合は、
%   分割兄弟も同じ名目柱の要素として結果へ追加する。
%
%   入力引数:
%     idx           - X通り番号範囲 [n x 2]
%     idy           - Y通り番号範囲 [n x 2]
%     idz           - Z通り番号範囲 [n x 2]
%     member_column - 柱部材テーブル
%
%   出力引数:
%     idmec - 柱部材番号

% 通り番号から柱部材番号を検索
n = size(idx,1);
idxlist = member_column.idx';
idylist = member_column.idy';
idzlist = member_column.idz';
nmec = size(idxlist,2);
istarget = false(1,nmec);
for i = 1:n
  % 柱の開始Z層番号が検索範囲に含まれる柱を対象にする
  xm = idx(i,1) <= idxlist(1,:) & idxlist(2,:) <= idx(i,2);
  ym = idy(i,1) <= idylist(1,:) & idylist(2,:) <= idy(i,2);
  zm = idz(i,1) <= idzlist(1,:) & idzlist(1,:) < idz(i,2);
  istarget = istarget | (xm & ym & zm);
end
idmec = find(istarget)';

% 元の名目柱を指定する入力は上下両方の分割要素へ適用する
has_idsplit = isfield(member_column, 'idsplit') || ...
  (istable(member_column) && ismember('idsplit', ...
  member_column.Properties.VariableNames));
if ~isempty(idmec) && has_idsplit
  idsibling = member_column.idsplit(idmec);
  idsibling = idsibling(idsibling > 0);
  idmec = unique([idmec idsibling(:)'], 'stable');
end

return
end
