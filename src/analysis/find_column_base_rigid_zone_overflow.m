function overflow = find_column_base_rigid_zone_overflow(lrcolumnx, ...
  lrcolumny, lrcolumnn, lm_column, member_column)
%find_column_base_rigid_zone_overflow - 柱脚剛域の超過を検出する
%
%   overflow = find_column_base_rigid_zone_overflow(lrcolumnx, ...
%     lrcolumny, lrcolumnn, lm_column, member_column) は、
%   ブレース取付位置で
%   分割された柱の柱脚剛域が下側区間長を超える箇所を検出し、
%   警告用の診断テーブルを返す。剛域長と部材長は変更しない。
%
%   入力引数:
%     lrcolumnx     - X方向柱剛域長 [nmec x 2] (mm)
%     lrcolumny     - Y方向柱剛域長 [nmec x 2] (mm)
%     lrcolumnn     - 材軸方向柱剛域長 [nmec x 2] (mm)
%     lm_column     - 柱部材長 [nmec x 1] (mm)
%     member_column - 柱部材テーブル
%
%   出力引数:
%     overflow - 超過箇所の診断テーブル [n x 5]
%       idme              - 柱部材番号
%       idir              - 剛域方向列番号（1:X、2:Y、3:材軸）
%                           PRM方向定数とは別の局所添字
%       rigid_zone_length - 柱脚剛域長 (mm)
%       lower_length      - 下側区間長 (mm)
%       overflow_length   - 無視する長さ (mm)

% 柱脚側剛域と下側区間長の差から超過を方向別に判定する
rigid_zone_base = [lrcolumnx(:, 1), lrcolumny(:, 1), lrcolumnn(:, 1)];
overflow_length = rigid_zone_base - lm_column(:, [1, 1, 1]);
is_foundation = member_column.type == PRM.COLUMN_FOR_BRACE_FOUNDATION;
is_overflow = is_foundation(:, [1, 1, 1]) & ...
  overflow_length > PRM.TOL_RIGID_ZONE_OVERFLOW_MM;

% 柱、方向の順で診断テーブルへ格納する
[imc, idir] = find(is_overflow);
entries = sortrows([imc, idir]);
imc = entries(:, 1);
idir = entries(:, 2);
identry = sub2ind(size(is_overflow), imc, idir);
overflow = table(member_column.idme(imc), idir, ...
  rigid_zone_base(identry), lm_column(imc), overflow_length(identry), ...
  'VariableNames', {'idme', 'idir', 'rigid_zone_length', ...
  'lower_length', 'overflow_length'});

return
end
