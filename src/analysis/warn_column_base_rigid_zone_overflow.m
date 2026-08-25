function warn_column_base_rigid_zone_overflow(overflow)
%warn_column_base_rigid_zone_overflow - 柱脚剛域の超過を警告する
%
%   warn_column_base_rigid_zone_overflow(overflow) は、
%   find_column_base_rigid_zone_overflowで検出した柱脚剛域の
%   超過箇所を、柱部材番号・方向・無視する長さ付きで警告する。
%   超過量は再計算せず、保持された診断情報だけを整形する。
%
%   入力引数:
%     overflow - 超過箇所の診断テーブル [n x 5]
%                (idme, idir, rigid_zone_length, lower_length,
%                 overflow_length)
%
%   出力引数:
%     なし

direction_names = {'X', 'Y', '材軸'};
for irow = 1:height(overflow)
  throw_warn('Analysis', 'ColumnBaseRigidZoneOverflow', ...
    overflow.idme(irow), direction_names{overflow.idir(irow)}, ...
    overflow.rigid_zone_length(irow), overflow.lower_length(irow), ...
    overflow.overflow_length(irow));
end

return
end
