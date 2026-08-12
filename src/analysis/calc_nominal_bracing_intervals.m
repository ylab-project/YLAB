function bracing = calc_nominal_bracing_intervals(axis_length, ...
  auto_points, input_points, is_replace, check_positions)
%calc_nominal_bracing_intervals - 名目部材の方向別補剛区間を生成
%
%   bracing = calc_nominal_bracing_intervals(axis_length,
%     auto_points, input_points, is_replace, check_positions) は、
%   1つの名目部材の1方向について、自動認識補剛点と直接指定補剛点
%   から有効な補剛点列を合成し、隣接補剛点間の補剛区間と、各検定
%   位置が参照する左右の補剛区間を求める。
%
%   部材種別と接続テーブルを参照しない純粋関数であり、どの接続
%   部材を補剛点とみなすかは呼び出し側の方向別規則が決める。
%   解析セグメント長 lm と名目部材全長 lnm はどちらも座屈長では
%   なく、補剛区間は補剛点間距離だけから生成する。
%
%   入力引数:
%     axis_length     - 名目部材の構造心間全長 [mm]
%     auto_points     - 自動認識した補剛位置の部材軸座標 [na×1]
%     input_points    - 直接指定による補剛位置の部材軸座標 [ni×1]
%     is_replace      - 直接指定の方式。true は置換で自動認識点を
%                       除外し、false は追加で和集合を採る
%     check_positions - 補剛区間を対応付ける検定位置 [nchk×1]
%
%   出力引数:
%     bracing - 方向別補剛区間 (struct)
%       .axis_length    - 名目部材の構造心間全長
%       .auto_points    - 入力された自動認識位置 [na×1]
%       .input_points   - 入力された直接指定位置 [ni×1]
%       .points         - 有効補剛位置（昇順、両端を含む）[np×1]
%       .intervals      - 隣接補剛点間距離 [(np-1)×1]
%       .count          - 補剛区間数
%       .max            - 最大補剛区間長
%       .check_interval - 検定位置ごとの左右候補 (struct)
%
%   備考:
%     - 検定位置が内部の補剛点と一致する場合だけ左右が別区間になる
%     - 補剛点と一致しない内部位置では左右とも同じ区間を返す
%     - 部材端では外側の候補を生成せず、区間番号0・長さNaNとする
%     - 入力値の妥当性は入力層と座標変換境界で検証済みとする
%     - 範囲外や非有限の値は除外も補正もせず点列へそのまま残す

% 位置の同一視に用いる許容差 [mm]
TOL_POINT = 1e-6;

% 有効補剛点の合成（置換では自動認識点を採らない）
if is_replace
  candidates = input_points(:);
else
  candidates = [auto_points(:); input_points(:)];
end

points = merge_bracing_points(candidates, axis_length, TOL_POINT);
intervals = diff(points);

bracing.axis_length = axis_length;
bracing.auto_points = auto_points(:);
bracing.input_points = input_points(:);
bracing.points = points;
bracing.intervals = intervals;
bracing.count = numel(intervals);
bracing.max = max(intervals);
bracing.check_interval = assign_check_intervals(points, ...
  intervals, check_positions(:), TOL_POINT);

return
end

%--------------------------------------------------------------
function points = merge_bracing_points(candidates, axis_length, tol)
%merge_bracing_points - 補剛点列を正規化し両端を含む列にする
%
%   points = merge_bracing_points(candidates, axis_length, tol) は、
%   端点の許容差内にある候補点を端点へ吸収し、許容差内で重複する
%   点を1点へ統合したうえで、両端を必ず含む昇順の補剛点列を返す。
%   端点への吸収によりゼロ長の補剛区間は生じない。範囲外や非有限
%   の候補は除外も補正もせず、そのまま点列へ残す。不正値は区間の
%   不変条件の破れとして下流で可視化される。
%
%   入力引数:
%     candidates  - 補剛点候補の部材軸座標 [n×1]
%     axis_length - 名目部材の構造心間全長
%     tol         - 位置の同一視に用いる許容差
%
%   出力引数:
%     points - 有効補剛位置（昇順、両端を含む）[np×1]

is_end = abs(candidates) <= tol | abs(candidates - axis_length) <= tol;
inner = sort(candidates(~is_end));

% 直前に採用した点との距離が許容差以内なら同一点とみなす
ninner = numel(inner);
keep = true(ninner, 1);
last = -inf;
for i = 1:ninner
  if inner(i) - last <= tol
    keep(i) = false;
  else
    last = inner(i);
  end
end

points = [0; inner(keep); axis_length];

return
end

%--------------------------------------------------------------
function check_interval = assign_check_intervals(points, ...
  intervals, check_positions, tol)
%assign_check_intervals - 検定位置へ左右の補剛区間を対応付ける
%
%   check_interval = assign_check_intervals(points, intervals,
%     check_positions, tol) は、各検定位置について左側と右側の
%   補剛区間を求める。内部の補剛点と一致する位置では前後の区間を
%   別候補として保持し、部材端では存在しない外側の区間を作らない。
%
%   入力引数:
%     points          - 有効補剛位置（昇順、両端を含む）[np×1]
%     intervals       - 隣接補剛点間距離 [(np-1)×1]
%     check_positions - 検定位置の部材軸座標 [nchk×1]
%     tol             - 位置の同一視に用いる許容差
%
%   出力引数:
%     check_interval - 検定位置ごとの左右候補 (struct)
%       .id_left  - 左側補剛区間の番号（無い場合0）[nchk×1]
%       .id_right - 右側補剛区間の番号（無い場合0）[nchk×1]
%       .left     - 左側補剛区間長（無い場合NaN）[nchk×1]
%       .right    - 右側補剛区間長（無い場合NaN）[nchk×1]

nchk = numel(check_positions);
nint = numel(intervals);
id_left = zeros(nchk, 1);
id_right = zeros(nchk, 1);

for i = 1:nchk
  x = check_positions(i);
  % 検定位置以下で最も右にある補剛点
  ip = find(points <= x + tol, 1, 'last');
  if abs(points(ip) - x) <= tol
    % 補剛点上では前後を別候補とする（端では外側を作らない）
    id_left(i) = ip - 1;
    if ip <= nint
      id_right(i) = ip;
    end
  else
    % 区間内部では左右とも同じ区間を参照する
    id_left(i) = ip;
    id_right(i) = ip;
  end
end

has_left = id_left > 0;
has_right = id_right > 0;
left = nan(nchk, 1);
right = nan(nchk, 1);
left(has_left) = intervals(id_left(has_left));
right(has_right) = intervals(id_right(has_right));

check_interval.id_left = id_left;
check_interval.id_right = id_right;
check_interval.left = left;
check_interval.right = right;

return
end
