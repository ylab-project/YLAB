function idmeg = find_idgirder_from_idxyz(idx, idy, ...
  idz, member_girder, idir, baseline)
%find_idgirder_from_idxyz - 通り番号から梁部材番号を検索
%
%   idmeg = find_idgirder_from_idxyz(...
%     idx, idy, idz, member_girder, idir,
%     baseline) は、
%   通りインデックスの範囲指定に基づいて
%   該当する梁部材番号を検索する。
%
%   入力引数:
%     idx           - x通りインデックス [n×2]
%     idy           - y通りインデックス [n×2]
%     idz           - z通りインデックス [n×2]
%     member_girder - 梁部材テーブル
%     idir          - 方向 [n×1]（省略可）
%     baseline      - 通り座標（省略可）
%
%   出力引数:
%     idmeg - 梁部材番号 [n×ncol]
n = size(idx,1);
idmeg = zeros(n,100);

% 向きを考慮するか
MODE_DIR = nargin >= 5 && ~isempty(idir);
USE_COORD = nargin >= 6 && ~isempty(baseline);

% 通り番号から梁部材番号の検索
idxlist = member_girder.idx;
idylist = member_girder.idy;
idzlist = member_girder.idz;
idirlist = member_girder.idir;
ncol = 1;
for i=1:n
  % 各次元の検索条件
  % 単一通り(start==end): 両端完全一致
  % 範囲指定: 部材が検索範囲に包含されるか
  if USE_COORD
    xm = range_match_coord(idx(i,:), idxlist, baseline.x.coord);
    ym = range_match_coord(idy(i,:), idylist, baseline.y.coord);
  else
    xm = range_match(idx(i,:), idxlist);
    ym = range_match(idy(i,:), idylist);
  end
  zm = range_match(idz(i,:), idzlist);

  if MODE_DIR
    id = find(xm & ym & zm & idir(i) == idirlist);
  else
    id = find(xm & ym & zm);
  end
  if ~isempty(id)
    ncol = max(ncol,length(id));
    idmeg(i,1:length(id)) = id;
  end
end

% 分割梁兄弟の追加（idsplitをたどる）
if isfield(member_girder, 'idsplit') || ...
    (istable(member_girder) && ismember('idsplit', ...
    member_girder.Properties.VariableNames))
  idsplit = member_girder.idsplit;
  for i = 1:n
    jmax = nnz(idmeg(i,:));
    for j = 1:jmax
      sib = idsplit(idmeg(i,j));
      if sib > 0 && ~any(idmeg(i,:) == sib)
        % グループ始端・終端が検索範囲内か検証
        grp = sort([idmeg(i,j), sib]);
        if ~check_group_range(grp, idxlist, idx(i,:), ...
            idylist, idy(i,:), baseline)
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
  m = (list(:,1) == r(1)) & (list(:,2) == r(2));
else
  m = (r(1) <= list(:,1)) & (list(:,2) <= r(2));
end

return
end


function m = range_match_coord(r, list, coord)
%range_match_coord - 物理座標ベースの範囲一致判定
%
%   m = range_match_coord(r, list, coord) は、
%   通りインデックスを物理座標に変換してから
%   範囲一致を判定する。ダミー通りの
%   インデックス逆転問題を回避する。
%
%   入力引数:
%     r     - 検索範囲（通りインデックス） [1×2]
%     list  - 部材座標（通りインデックス） [nm×2]
%     coord - 通り座標テーブル [naxis×1]
%
%   出力引数:
%     m - 一致フラグ [nm×1 logical]

if r(1) == r(2)
  m = (list(:,1) == r(1)) & (list(:,2) == r(2));
else
  cr = sort(coord(r));
  cl1 = coord(list(:,1));
  cl2 = coord(list(:,2));
  lo = min(cl1, cl2);
  hi = max(cl1, cl2);
  m = (cr(1) <= lo) & (hi <= cr(2));
end

return
end


function ok = check_group_range(grp, idxlist, xr, idylist, yr, baseline)
%check_group_range - 分割梁グループの範囲検証
%
%   ok = check_group_range(grp, idxlist, xr,
%     idylist, yr, baseline) は、
%   分割梁グループの始端(先頭部材のi端)と
%   終端(末尾部材のj端)が検索範囲内かを検証する。
%   baseline指定時は物理座標で判定する。
%
%   入力引数:
%     grp      - 梁番号（昇順） [1×k]
%     idxlist  - 全梁のx通り [nm×2]
%     xr       - x検索範囲 [1×2]
%     idylist  - 全梁のy通り [nm×2]
%     yr       - y検索範囲 [1×2]
%     baseline - 通り座標（省略可）
%
%   出力引数:
%     ok - 範囲内フラグ（スカラーlogical）

if nargin >= 6 && ~isempty(baseline)
  xcoord = baseline.x.coord;
  ycoord = baseline.y.coord;
  xs = xcoord(idxlist(grp(1), 1));
  xe = xcoord(idxlist(grp(end), 2));
  xrs = sort(xcoord(xr));
  if xs < xrs(1) || xe > xrs(2)
    ok = false; return
  end
  ys = ycoord(idylist(grp(1), 1));
  ye = ycoord(idylist(grp(end), 2));
  yrs = sort(ycoord(yr));
  if ys < yrs(1) || ye > yrs(2)
    ok = false; return
  end
  ok = true;
else
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
end

return
end

