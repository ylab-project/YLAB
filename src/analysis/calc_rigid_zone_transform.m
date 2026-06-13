function tr = calc_rigid_zone_transform(lrx, lry, cxl, cyl, czl, ...
  iscolumn)
%calc_rigid_zone_transform - 剛域オフセットの座標変換行列を作成
%
%   tr = calc_rigid_zone_transform(lrx, lry, cxl, cyl, czl,
%     iscolumn) は、剛域オフセット変換行列 [12×12] を作成する。
%   要素剛性 ke に対し ke_node = tr' * ke * tr の形で用いる。
%
%   柱では、方向別剛域長 (lrx, lry) と対応する曲げ面を回転断面基底
%   （鉛直軸 ez を柱軸へ回す最小回転による ex, ey の像）の面として
%   解釈する。剛域は取り付く梁の梁せい区間へ貫入する柱軸線上の区間
%   であり、方向別性は梁の方向（全体座標系）に由来し断面の向きとは
%   独立のため。部材局所断面軸 (cyl, czl) が回転断面基底とずれる
%   3D傾斜柱等では、断面内回転を変換へ合成する。鉛直柱・X軸沿い
%   傾斜柱（材軸回転角0）では断面内回転が恒等となり従来と同一。
%   梁は従来どおり部材局所面で適用する。
%
%   入力引数:
%     lrx      - X方向剛域長 [1×2]（柱脚/左端, 柱頭/右端）
%     lry      - Y方向剛域長 [1×2]
%     cxl      - 部材座標x軸の方向余弦 [1×3]
%     cyl      - 部材座標y軸の方向余弦 [1×3]
%     czl      - 部材座標z軸の方向余弦 [1×3]
%     iscolumn - 柱フラグ（true: 回転断面基底面で適用）
%
%   出力引数:
%     tr - 剛域オフセット変換行列 [12×12]
%
%   参考:
%     stif_sys_matrix, calc_member_force, calc_rigid_zone_column

tr = eye(12);
tr(3,5) = -lrx(1);
tr(9,11) = lrx(2);
tr(2,6) = lry(1);
tr(8,12) = -lry(2);
if ~iscolumn
  return
end

% 回転断面基底（ez を柱軸 cxl へ回す最小回転による ex, ey の像）
albar = sqrt(cxl(1)^2 + cxl(2)^2);
if albar < 1e-9
  % 鉛直柱: 基底は全体 ex, ey
  e1 = [1 0 0];
  e2 = [0 1 0];
else
  k = [-cxl(2) cxl(1) 0] / albar;
  c = cxl(3);
  e1 = [1 0 0] * c + cross(k, [1 0 0]) * albar + k * k(1) * (1 - c);
  e2 = [0 1 0] * c + cross(k, [0 1 0]) * albar + k * k(2) * (1 - c);
end

% 局所断面 (cyl, czl) 成分を回転断面フレーム (e2, -e1) 成分へ回す
% 断面内回転。恒等（鉛直・X軸沿いで材軸回転角0）なら従来どおり
q11 = dot(e2, cyl);
q12 = dot(e2, czl);
if abs(q11 - 1) < 1e-12 && abs(q12) < 1e-12
  return
end
Q3 = [1 0 0; 0 q11 q12; 0 -dot(e1, cyl) -dot(e1, czl)];
QQ = blkdiag(Q3, Q3, Q3, Q3);
tr = tr * QQ;

return
end
