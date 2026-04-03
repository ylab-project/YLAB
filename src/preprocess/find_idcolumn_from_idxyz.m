function idmec = find_idcolumn_from_idxyz(idx, idy, idz, member_column)
%find_idcolumn_from_idxyz - 座標範囲から柱部材番号を検索
%
%   idmec = find_idcolumn_from_idxyz(...
%     idx, idy, idz, member_column) は、
%   指定されたX, Y, Z座標範囲に合致する
%   柱部材のIDを返す。
%   柱の開始Z層番号がidz(1)と一致するものを検索。
%
%   入力引数:
%     idx           - X通り番号範囲 [n×2]
%     idy           - Y通り番号範囲 [n×2]
%     idz           - Z通り番号範囲 [n×2]
%     member_column - 柱部材テーブル
%
%   出力引数:
%     idmec - 柱部材番号

% 計算の準備
n = size(idx,1);
idmec = [];

% 通り番号から柱部材番号の検索
idxlist = member_column.idx';
idylist = member_column.idy';
idzlist = member_column.idz';
nmec = size(idxlist, 2);
istarget = false(1,nmec);
for i=1:n
  % 柱の開始Z層番号が検索Z層番号と一致
  xm = idx(i,1) <= idxlist(1,:) & idxlist(2,:) <= idx(i,2);
  ym = idy(i,1) <= idylist(1,:) & idylist(2,:) <= idy(i,2);
  zm = idz(i,1) <= idzlist(1,:) & idzlist(1,:) < idz(i,2);
  istarget = istarget | (xm & ym & zm);
end
if any(istarget)
  idmec = find(istarget)';
end

return
end
