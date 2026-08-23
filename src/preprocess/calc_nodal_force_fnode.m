function fnode = calc_nodal_force_fnode(nodal_force, nnode, nlc)
%calc_nodal_force_fnode - 節点荷重テーブルを解析用配列へ加算する
%
%   fnode = calc_nodal_force_fnode(nodal_force, nnode, nlc) は、共通内部
%   データの節点荷重6成分を同一節点・同一解析荷重ケースで線形加算
%   する。解析非計上行は除外する（内部設計6章）。
%
%   入力引数:
%     nodal_force - 節点荷重テーブル（idnode・ilc・f列を参照）
%     nnode       - 節点数
%     nlc         - 荷重ケース数
%
%   出力引数:
%     fnode - 全体座標系の節点荷重 [nnode×6×nlc]
fnode = zeros(nnode, 6, nlc);
idnode = nodal_force.idnode;
ilc = nodal_force.ilc;
row_f = nodal_force.f;
for k = 1:length(idnode)
  if ilc(k) == 0
    continue
  end
  fnode(idnode(k), :, ilc(k)) = fnode(idnode(k), :, ilc(k)) + row_f(k, :);
end

return
end
