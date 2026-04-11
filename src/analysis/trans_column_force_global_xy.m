function rs = trans_column_force_global_xy(rs, cxl, cyl, idmc2m)
%trans_column_force_global_xy - 斜め柱応力を全体系XY方向に変換
%
%   rs = trans_column_force_global_xy(rs, cxl, cyl, idmc2m) は、
%   斜め柱（柱軸が水平面成分を持つ柱）の部材端応力 rs のうち、
%   曲げ・せん断成分を局所直交基底から全体座標系XY方向に変換し
%   上書きする。軸力（cxl方向）とねじり（cxlまわり）の寄与は
%   除外し、軸力・ねじりは局所のまま保持する。これにより軸力・
%   ねじりと区別された純粋な「フレーム方向のせん断・曲げ」が
%   出力される（SS7互換）。鉛直柱（水平面成分が微小）は変更
%   しない。
%
%   入力引数:
%     rs     - 部材端応力 [nme×12×nlc]
%     cxl    - 部材軸方向余弦 [nme×3]
%     cyl    - 局所y軸方向余弦（直交） [nme×3]
%     idmc2m - 柱番号→部材番号変換 [nmc×1]
%
%   出力引数:
%     rs - 部材端応力（斜め柱のみ上書き）[nme×12×nlc]

nlc = size(rs, 3);
nmc = length(idmc2m);
% 局所z軸（一括計算してループ内の再計算を避ける）
czl = cross(cxl, cyl, 2);
for ic = 1:nmc
  im = idmc2m(ic);
  cx = cxl(im, :);
  if sqrt(cx(1)^2 + cx(2)^2) < 1e-6
    continue  % 鉛直柱: 変換不要
  end
  cy = cyl(im, :);
  cz = czl(im, :);
  t = [cx; cy; cz];  % rows = 局所軸を全体系で表現

  % 全荷重ケースを一括で変換（12×nlc にreshape）
  R = reshape(rs(im, :, :), 12, nlc);
  z = zeros(1, nlc);
  % 軸力（cxl方向）・ねじり（cxlまわり）は0に差し替えて
  % せん断・曲げの全体系成分のみを算定する
  F_i = t' * [z; R(2, :); R(3, :)];
  M_i = t' * [z; R(5, :); R(6, :)];
  F_j = t' * [z; R(8, :); R(9, :)];
  M_j = t' * [z; R(11, :); R(12, :)];
  % 全体系XY方向成分で該当行を上書き（軸力 R(1,:)/R(7,:) と
  % ねじり R(4,:)/R(10,:) は局所のまま）
  R(2, :)  =  F_i(2, :);  R(3, :)  = -F_i(1, :);
  R(5, :)  =  M_i(2, :);  R(6, :)  = -M_i(1, :);
  R(8, :)  =  F_j(2, :);  R(9, :)  = -F_j(1, :);
  R(11, :) =  M_j(2, :);  R(12, :) = -M_j(1, :);
  rs(im, :, :) = reshape(R, 1, 12, nlc);
end

return
end
