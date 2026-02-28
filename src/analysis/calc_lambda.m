function [lamy, lamz] = calc_lambda(A, Iy, Iz, mtype, stype, lkx, lky)
%CALC_LAMBDA 細長比の計算
% 概要: 座屈長と断面諸元から細長比を計算する
% 構文: [lamy, lamz] = calc_lambda(A, Iy, Iz, mtype, stype, lkx, lky)
% 入力:
%   A     - 断面積 [nme×1]
%   Iy    - 断面二次モーメント Y軸 [nme×1]
%   Iz    - 断面二次モーメント Z軸 [nme×1]
%   mtype - 部材タイプ [nme×1]
%   stype - 断面タイプ [nme×1]
%   lkx   - X方向座屈長 [nme×1]
%   lky   - Y方向座屈長 [nme×3]（左端,右端,中央）
% 出力:
%   lamy  - X方向細長比 [nme×1]
%   lamz  - Y方向細長比 [nme×3]

nme = length(mtype);

% 断面二次半径
iy = sqrt(Iy./A);
iz = sqrt(Iz./A);

% 細長比
lamy = lkx./iy;
lamz = lky./iz;

% ブレースは中間補剛なし：全区間で同一の細長比
ib = mtype == PRM.BRACE;
lamz(ib, 2) = lamz(ib, 1);
lamz(ib, 3) = lamz(ib, 1);

% RC柱は座屈を考慮しない
for im = 1:nme
  if mtype(im) == PRM.COLUMN && stype(im) == PRM.RCRS
    lamy(im) = 0;
    lamz(im,:) = 0;
  end
end

return
end
