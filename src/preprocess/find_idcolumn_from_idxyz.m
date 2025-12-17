function idmec = find_idcolumn_from_idxyz(idx, idy, idz, member_column)
%FIND_IDCOLUMN_FROM_IDXYZ 座標範囲から柱部材番号を検索
%   idmec = find_idcolumn_from_idxyz(idx, idy, idz, member_column)
%   指定されたX, Y, Z座標範囲に合致する柱部材のIDを返します。
%
%   入力:
%       idx - 検索対象のX通り番号範囲 [開始X, 終了X]
%       idy - 検索対象のY通り番号範囲 [開始Y, 終了Y]
%       idz - 検索対象のZ通り番号範囲 [開始Z, 終了Z]
%             ※この関数では、柱の開始Z層番号がidz(1)と厳密に一致するものを検索します。
%       member_column - 柱部材テーブル
%
%   出力:
%       idmec - 合致する柱部材のIDリスト

% 計算の準備
nmec = size(member_column,1);
n = size(idx,1);
idmec = [];

% 通り番号から柱部材番号の検索
idxlist = member_column.idx';
idylist = member_column.idy';
idzlist = member_column.idz';
istarget = false(1,nmec);
for i=1:n
  istarget = istarget | (...
    idx(i,1) <= idxlist(1,:) & idxlist(2,:) <= idx(i,2) &...
    idy(i,1) <= idylist(1,:) & idylist(2,:) <= idy(i,2) & ...
    idz(i,1) <= idzlist(1,:) & idzlist(1,:) < idz(i,2)); % 柱の開始Z層番号が検索Z層番号と厳密に一致
end
if ~isempty(istarget)
  iddd = (1:nmec)';
  idmec = iddd(istarget);
end

return
end
