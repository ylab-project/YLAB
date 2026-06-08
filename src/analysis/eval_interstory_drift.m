function [condrift, drift_angle, idcolumn, dx, dy, drift_height, ...
  drift_delta_x, drift_delta_y] = eval_interstory_drift( ...
  dispnode, floor_height, lcdir, dmax, idfl2s, idmc2st, idc2n, ...
  idn2st, floor_standard_height, options)
%eval_interstory_drift - 層間変形角制約を評価する

% 定数
nlc = size(dispnode, 3);
nfl = length(idfl2s);
nmc = size(idmc2st, 1);
nph = options.num_penthouse_floor;
ncalc_floor = nfl - nph;
tie_tolerance = 1e-12;

% 計算の準備
dx = zeros(nmc, nlc);
dy = zeros(nmc, nlc);
drift_angle = zeros(ncalc_floor, nlc);
idcolumn = zeros(nfl, nlc);
drift_height = zeros(ncalc_floor, nlc);
drift_delta_x = zeros(ncalc_floor, nlc);
drift_delta_y = zeros(ncalc_floor, nlc);

% 柱の下端・上端節点と層番号
node1 = idc2n(:, 1);
node2 = idc2n(:, 2);
story1 = idn2st(node1);
story2 = idn2st(node2);
is_reversed = story1 > story2;
bottom_node = node1;
top_node = node2;
bottom_node(is_reversed) = node2(is_reversed);
top_node(is_reversed) = node1(is_reversed);
bottom_story = min(story1, story2);
top_story = max(story1, story2);

% 各柱位置での層間変形角（符号保存）
for icol = 1:nmc
  dx_top = dispnode(top_node(icol), 1, :);
  dx_bottom = dispnode(bottom_node(icol), 1, :);
  dy_top = dispnode(top_node(icol), 2, :);
  dy_bottom = dispnode(bottom_node(icol), 2, :);
  dx_delta = reshape(dx_top - dx_bottom, 1, []);
  dy_delta = reshape(dy_top - dy_bottom, 1, []);
  if floor_height(icol, 1) > 0
    dx(icol, :) = dx_delta / floor_height(icol, 1);
  end
  if floor_height(icol, 2) > 0
    dy(icol, :) = dy_delta / floor_height(icol, 2);
  end
end

% 柱chainの実効上端柱と結合高さを前計算（荷重ケース・階に不変）。
% 上柱の階高が 0 の場合に下柱と結合して評価するための対応表。
upper_of = zeros(nmc, 1);
combined_height = zeros(nmc, 1);
for icol = 1:nmc
  uc = find(bottom_node == top_node(icol) ...
    & top_story > bottom_story(icol), 1);
  if ~isempty(uc)
    upper_of(icol) = uc;
    in_range = idfl2s > bottom_story(icol) & idfl2s <= top_story(uc);
    combined_height(icol) = sum(floor_standard_height(in_range));
  end
end

% 荷重ケースごとの最大層間変形角
for ifl = 1:ncalc_floor
  target_story = idfl2s(ifl);
  for ilc = 1:nlc
    switch ilc
      case {PRM.EXP, PRM.EXN}
        idxy = 1;
      case {PRM.EYP, PRM.EYN}
        idxy = 2;
      otherwise
        continue
    end
    best_angle = 0;
    best_col = 0;
    best_height = 0;
    best_dx = 0;
    best_dy = 0;

    for icol = 1:nmc
      % 通常柱: 自身の階高で評価
      if bottom_story(icol) < target_story ...
          && target_story <= top_story(icol)
        try_candidate(bottom_node(icol), top_node(icol), ...
          floor_height(icol, idxy));
      end
      % 結合柱: 上柱の階高が 0 のとき実効高さで評価
      uc = upper_of(icol);
      if uc > 0 && floor_height(uc, idxy) == 0 ...
          && bottom_story(icol) < target_story ...
          && target_story <= top_story(uc)
        try_candidate(bottom_node(icol), top_node(uc), ...
          combined_height(icol));
      end
    end
    drift_angle(ifl, ilc) = best_angle;
    idcolumn(ifl, ilc) = best_col;
    drift_height(ifl, ilc) = best_height;
    drift_delta_x(ifl, ilc) = best_dx;
    drift_delta_y(ifl, ilc) = best_dy;
  end
end

% 制約関数値に変換（絶対値で評価）
condrift = reshape(abs(drift_angle(:, lcdir > 1)), [], 1) * dmax - 1;
return

  function try_candidate(b_node, t_node, height)
  %try_candidate - 候補柱の層間変形角を評価し最大値を更新する（内部）
    if height <= 0
      return
    end
    ddx = dispnode(t_node, 1, ilc) - dispnode(b_node, 1, ilc);
    ddy = dispnode(t_node, 2, ilc) - dispnode(b_node, 2, ilc);
    if idxy == 1
      ang = ddx / height;
    else
      ang = ddy / height;
    end
    if best_col == 0 || abs(ang) > abs(best_angle) + tie_tolerance
      best_angle = ang;
      best_col = icol;
      best_height = height;
      best_dx = ddx;
      best_dy = ddy;
    end
    return
  end
end
