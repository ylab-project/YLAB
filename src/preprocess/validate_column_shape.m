function validate_column_shape(section_column, member_column, ...
  section_column_base)
%validate_column_shape - H形鋼柱の未対応指定を入力境界で止める
%
%   validate_column_shape(section_column, member_column,
%     section_column_base) は、柱用H形鋼（CWFS／CWFSI）の柱断面に
%   柱の回転角（0以外）または柱脚リストが指定されていないことを
%   確認する。強軸の向きはH／Iで指定し、柱配置の角度では指定しない。
%
%   入力引数:
%     section_column      - 柱断面テーブル（type, full_name, floor_name）
%     member_column       - 柱部材テーブル（idsecc, angle）
%     section_column_base - 柱脚断面テーブル（type, idsecc）

% H形鋼リストを利用する柱断面が柱用H形鋼
is_hshape = PRM.list_type_of_section_type(section_column.type) == PRM.WFS;

% 柱の回転角（柱配置の第5列）
imc = find(is_hshape(member_column.idsecc) & member_column.angle ~= 0, 1);
if ~isempty(imc)
  isc = member_column.idsecc(imc);
  throw_err('Input', 'ColumnShapeRotationUnsupported', ...
    section_column.floor_name{isc}, section_column.full_name{isc}, ...
    member_column.angle(imc));
end

% 柱脚リスト（メーカー製柱脚断面の剛性指定以外）
iscb = find(section_column_base.type == PRM.CB_LIST ...
  & is_hshape(section_column_base.idsecc), 1);
if ~isempty(iscb)
  isc = section_column_base.idsecc(iscb);
  throw_err('Input', 'ColumnBaseListShapeUnsupported', ...
    section_column.floor_name{isc}, section_column.full_name{isc});
end

return
end
