function idmeg = find_idgirder_from_idxyz(...
  idx, idy, idz, member_girder, idir)
%find_idgirder_from_idxyz - 通り番号から梁部材番号を検索
n = size(idx,1);
idmeg = zeros(n,100);

% 向きを考慮するか
if nargin==4
  MODE_DIR=false;
else
  MODE_DIR=true;
end

% 通り番号から梁部材番号の検索
idxlist = member_girder.idx;
idylist = member_girder.idy;
idzlist = member_girder.idz;
idirlist = member_girder.idir;
iddd = (1:size(member_girder,1))';
ncol = 1;
for i=1:n
  % 各次元の検索条件
  % 単一通り(start==end): 両端完全一致
  % 範囲指定: 部材が検索範囲に包含されるか
  xm = range_match(idx(i,:), idxlist);
  ym = range_match(idy(i,:), idylist);
  zm = range_match(idz(i,:), idzlist);

  if MODE_DIR
    id = iddd(xm & ym & zm ...
      & idir(i) == idirlist);
  else
    id = iddd(xm & ym & zm);
  end
  if ~isempty(id)
    ncol = max(ncol,length(id));
    idmeg(i,1:length(id)) = id;
  end
end

% 分割梁兄弟の追加（idsplitをたどる）
if ismember('idsplit', ...
    member_girder.Properties.VariableNames)
  idsplit = member_girder.idsplit;
  for i = 1:n
    jmax = nnz(idmeg(i,:));
    for j = 1:jmax
      sib = idsplit(idmeg(i,j));
      if sib > 0 && ~any(idmeg(i,:) == sib)
        % グループ始端・終端が検索範囲内か検証
        grp = sort([idmeg(i,j), sib]);
        if ~check_group_range(grp, ...
            idxlist, idx(i,:), ...
            idylist, idy(i,:))
          continue
        end
        jmax = jmax + 1;
        idmeg(i, jmax) = sib;
        ncol = max(ncol, jmax);
      end
    end
    % 通り順にソート（梁番号の昇順）
    if jmax > 1
      idmeg(i, 1:jmax) = sort(idmeg(i, 1:jmax));
    end
  end
end

idmeg = idmeg(:,1:ncol);
return
end


function m = range_match(r, list)
%range_match - 検索範囲と部材座標の一致判定
%
%   m = range_match(r, list) は、
%   検索範囲rに対して各部材の座標listが
%   一致するかを判定する。
%   単一通り(r(1)==r(2))は両端完全一致、
%   範囲指定は包含チェック。
%
%   入力引数:
%     r    - 検索範囲 [1×2]
%     list - 部材座標 [nm×2]
%
%   出力引数:
%     m - 一致フラグ [nm×1 logical]

if r(1) == r(2)
  m = (list(:,1) == r(1)) ...
    & (list(:,2) == r(2));
else
  m = (r(1) <= list(:,1)) ...
    & (list(:,2) <= r(2));
end

return
end


function ok = check_group_range(grp, ...
  idxlist, xr, idylist, yr)
%check_group_range - 分割梁グループの範囲検証
%
%   ok = check_group_range(grp, idxlist, xr,
%     idylist, yr) は、
%   分割梁グループの始端(先頭部材のi端)と
%   終端(末尾部材のj端)が検索範囲内かを検証する。
%
%   入力引数:
%     grp     - 梁番号（昇順） [1×k]
%     idxlist - 全梁のx座標 [nm×2]
%     xr      - x検索範囲 [1×2]
%     idylist - 全梁のy座標 [nm×2]
%     yr      - y検索範囲 [1×2]
%
%   出力引数:
%     ok - 範囲内フラグ（スカラーlogical）

xs = idxlist(grp(1), 1);
xe = idxlist(grp(end), 2);
if xs < xr(1) || xe > xr(2)
  ok = false; return
end
ys = idylist(grp(1), 1);
ye = idylist(grp(end), 2);
if ys < yr(1) || ye > yr(2)
  ok = false; return
end
ok = true;

return
end

