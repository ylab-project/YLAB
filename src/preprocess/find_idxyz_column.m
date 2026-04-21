function [idx, idy, idz] = find_idxyz_column(floor_name, ...
  xcoord_name, ycoord_name, baseline, story)
%find_idxyz_column - 柱の通り・階ID特定（「全/ALL」指定の展開対応）
%
%   [idx, idy, idz] = find_idxyz_column(floor_name, xcoord_name, ...
%     ycoord_name, baseline, story) は、入力の階名・X軸名・Y軸名を
%   baseline 上のIDレンジ [1×2] に変換する。柱はフレーム概念がない
%   ため 1→2 行展開はなく、出力行数は入力 n のまま。各入力列で
%   「全/ALL」が現れた場合は [1, nbl?] の全範囲レンジを返す。
%
%   入力引数:
%     floor_name  - 階名 [n×m] cell（m=1:単一指定, m=2:始端終端指定）
%     xcoord_name - X軸名 [n×m] cell
%     ycoord_name - Y軸名 [n×m] cell
%     baseline    - 通り情報構造体（.x.name, .y.name, .z.idnominal 等）
%     story       - ストーリー情報構造体（.floor_name 等）
%
%   出力引数:
%     idx - X軸IDレンジ [n×2]（始端ID, 終端ID）
%     idy - Y軸IDレンジ [n×2]
%     idz - 階Z-IDレンジ [n×2]（下端節点Z, 上端節点Z）

% 共通定数
n = size(floor_name,1);
m = size(floor_name,2);

% baseline 件数
nblx = size(baseline.x,1);
nbly = size(baseline.y,1);
nblz = size(baseline.z,1);

% 出力バッファ
idx = zeros(n,2); iddx = 1:nblx;
idy = zeros(n,2); iddy = 1:nbly;
idz = zeros(n,2); iddz = 1:nblz;
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = story.floor_name;

if m==1
  for i=1:n
    if is_all_token(xcoord_name{i,1})
      idx(i,:) = [1, nblx];
    else
      idx(i,1) = iddx(matches(xlist, xcoord_name{i,1}));
      idx(i,2) = idx(i,1);
    end
    if is_all_token(ycoord_name{i,1})
      idy(i,:) = [1, nbly];
    else
      idy(i,1) = iddy(matches(ylist, ycoord_name{i,1}));
      idy(i,2) = idy(i,1);
    end
    % 階：階ID-1（下端節点Z）～ 階ID（上端節点Z）
    if is_all_token(floor_name{i,1})
      idz(i,:) = [1, nblz];
    else
      idz(i,1) = iddz(matches(zlist, floor_name{i,1}))-1;
      idz(i,2) = idz(i,1)+1;
    end
  end
else
  for i=1:n
    if is_all_token(xcoord_name{i,1})
      idx(i,:) = [1, nblx];
    else
      idx(i,1) = iddx(matches(xlist, xcoord_name{i,1}));
      idx(i,2) = iddx(matches(xlist, xcoord_name{i,2}));
    end
    if is_all_token(ycoord_name{i,1})
      idy(i,:) = [1, nbly];
    else
      idy(i,1) = iddy(matches(ylist, ycoord_name{i,1}));
      idy(i,2) = iddy(matches(ylist, ycoord_name{i,2}));
    end
    if is_all_token(floor_name{i,1})
      idz(i,:) = [1, nblz];
    else
      idz(i,1) = iddz(matches(zlist, floor_name{i,1}))-1;
      idz(i,2) = iddz(matches(zlist, floor_name{i,2}));
    end
  end
end
return
end
