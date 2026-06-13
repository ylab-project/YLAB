function rs = trans_member_force_global_basis(rs, cxl, cyl, mtype, idmc2m)
%trans_member_force_global_basis - 部材応力を表示基底へ変換
%
%   rs = trans_member_force_global_basis(rs, cxl, cyl, mtype, idmc2m)
%   は、ケース別の部材端応力 rs を SS7 互換の表示基底へ変換する。
%   柱は全体系XY成分への射影後、回転断面基底へ補償する。梁・
%   ブレースは、YLAB の局所姿勢が SS7 の表示姿勢と一致する前提で
%   恒等とする。3D斜め梁の姿勢規約は未検証であり、ずれが判明
%   した場合は要素姿勢側で扱う。
%
%   入力引数:
%     rs     - 部材端応力 [nme×12×nlc]
%     cxl    - 部材x軸方向余弦 [nme×3]
%     cyl    - 部材y軸方向余弦 [nme×3]
%     mtype  - 部材種別 [nme×1]
%     idmc2m - 柱番号→部材番号変換 [nmc×1]
%
%   出力引数:
%     rs - 表示基底へ変換後の部材端応力 [nme×12×nlc]

if isempty(rs) || isempty(idmc2m)
  return
end

idcol = idmc2m(mtype(idmc2m) == PRM.COLUMN);
if isempty(idcol)
  return
end

rs = trans_column_force_global_xy(rs, cxl, cyl, idcol);
rs = convert_column_force_for_design(rs, cxl, cyl, idcol);

return
end
